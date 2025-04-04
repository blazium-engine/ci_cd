const https = require('https');
const fs = require('fs');
const path = require('path');

// Load environment variables from .env file
const token = process.env.GITHUB_TOKEN;
const owner = process.env.GITHUB_OWNER; // The owner of the repository
const repo = process.env.GITHUB_REPO; // The repository name
const currentBranch = process.env.CURRENT_BRANCH; // The current branch
const includeFiles = process.env.INCLUDE_FILES || false;

var baseBranch = process.env.BASE_BRANCH;

var version = {
    major: process.env.MAJOR_VERSION || 0,
    minor: process.env.MINOR_VERSION || 1,
    patch: process.env.PATCH_VERSION || 0,
    build_type: process.env.BUILD_TYPE || "nightly"
}

if (!token || !owner || !repo || !baseBranch || !currentBranch) {
    console.error("Error: Missing required environment variables.");
    process.exit(1);
}

// API base URL for the repository
const apiBaseUrl = `https://api.github.com/repos/${owner}/${repo}`;

function httpsGet(url, additionalHeaders = {}) {
    return new Promise((resolve, reject) => {
        const options = {
            method: 'GET',
            headers: {
                'Authorization': `token ${token}`,
                'Accept': 'application/vnd.github.v3+json',
                'User-Agent': 'blazium-engine/blazium ci/cd v1.0.0',
                ...additionalHeaders
            },
        };

        const req = https.request(url, options, (res) => {
            let data = '';

            res.on('data', (chunk) => (data += chunk));

            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    resolve({
                        data: JSON.parse(data),
                        headers: res.headers
                    });
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${data}`));
                }
            });
        });

        req.on('error', reject);
        req.end();
    });
}

async function setBaseBranch() {
    console.log(`[DEBUG] Getting baseBranch`);
    const response = await httpsGet(`${apiBaseUrl}/releases`, {
        'X-GitHub-Api-Version': '2022-11-28',
    });
    const gh_releases = response.data;
    for (let i = 0; i < gh_releases.length; i++) {
        const release = gh_releases[i];
        if (release.name.includes(version.build_type)) {
            baseBranch = release.target_commitish;
            console.log(`[DEBUG] The baseBranch was found: ${baseBranch}`);
            return;
        }
    }
    console.log(`[DEBUG] Warning: using env baseBranch! ${baseBranch}`);
}

async function getPaginatedData(url) {
    let commits = [];
    let files = new Set(); // Use a Set to ensure unique file names
    let page = 1;
    const perPage = 100;
    let totalCommits = 0;
    let pagesRemaining = true;

    console.log(`[DEBUG] Fetching paginated data from: ${url}`);

    while (pagesRemaining) {
        try {
            const paginatedUrl = `${url}?page=${page}&per_page=${perPage}`;
            console.log(`[DEBUG] Requesting page ${page}: ${paginatedUrl}`);

            const response = await httpsGet(paginatedUrl, {
                'X-GitHub-Api-Version': '2022-11-28',
            });

            //console.log(JSON.stringify(response, null, 5));

            if (page === 1) {
                totalCommits = response.data.total_commits || response.data.commits?.length || 0;
                console.log(`[DEBUG] Total commits to fetch: ${totalCommits}`);
            }

            // Check for the files field and add to files Set
            if (response.data.files?.length > 0) {
                response.data.files.forEach(file => files.add(file.filename));
                console.log(`[DEBUG] Page ${page} received ${response.data.files.length} file records`);
            }

            if (response.data.commits?.length > 0) {
                commits = [...commits, ...response.data.commits];
                console.log(`[DEBUG] Page ${page} received ${response.data.commits.length} commit records`);
            } else {
                console.log("[DEBUG] No more commit data on this page.");
                break;
            }

            if (commits.length >= totalCommits) {
                console.log("[DEBUG] All commits retrieved.");
                pagesRemaining = false;
            } else {
                page++;
            }
        } catch (error) {
            console.error(`[ERROR] Fetching data failed: ${error.message}`);
            break;
        }
    }

    console.log(`[DEBUG] Total commits fetched: ${commits.length}`);
    console.log(`[DEBUG] Total unique files fetched: ${files.size}`);

    return { 
        commits, 
        files: Array.from(files) // Convert Set to Array before returning
    };
}


// Function to compare two branches and get commits
async function compareBranches() {
    const url = `${apiBaseUrl}/compare/${baseBranch}...${currentBranch}`;
    return await getPaginatedData(url);
}


// Function to get the files changed in a specific commit
async function getCommitFiles(commitSha) {
    const url = `${apiBaseUrl}/commits/${commitSha}`;
    return await getPaginatedData(url);
}

// Function to generate a changelog and collect stats from the comparison data
async function generateChangelog(outputDir = __dirname) {
    const comparisonData = await compareBranches();
    if (!comparisonData) return;

    const commits = comparisonData.commits;
    const filesChanged = new Set();
    let totalPRs = 0;
    let firstChangeDate = null;
    let lastChangeDate = null;
    let contributorStats = {};
    let changelog = [];

    console.log(`Processing ${commits.length} commits...`);

    await Promise.all(
        commits.map(async commit => {
            const commitSha = commit.sha;
            const commitMessage = commit.commit.message;
            if (/#(skip)/i.test(commitMessage)) return;

            const commitDate = new Date(commit.commit.committer.date);
            const commitLogin = commit.author?.login || commit.commit.author.name;
            const commitUser = commit.commit.author.name;
            const prNumber = extractPRNumberFromCommitMessage(commitMessage);
            const semVerLabel = getSemVerLabel(commitMessage);

            if (includeFiles) {
                // Track file changes
                (await getCommitFiles(commitSha)).files.forEach(file => filesChanged.add(file));
            }

            // Track date range
            firstChangeDate = firstChangeDate ? Math.min(firstChangeDate, commitDate) : commitDate;
            lastChangeDate = lastChangeDate ? Math.max(lastChangeDate, commitDate) : commitDate;

            // Track contributor stats
            if (!contributorStats[commitLogin]) contributorStats[commitLogin] = { count: 0, commits: [], names: [] };
            contributorStats[commitLogin].count++;
            contributorStats[commitLogin].commits.push(commitSha);
            
            if (!contributorStats[commitLogin].names.includes(commitUser)) {
                contributorStats[commitLogin].names.push(commitUser);
            }

            // Track changelog
            changelog.push({ sha: commitSha, message: commitMessage, date: commitDate, user: commitLogin, name: commitUser, pr: prNumber, label: semVerLabel });

            // Versioning
            if (semVerLabel === "major") {
                version.major++;
                version.minor = 0;
                version.patch = 0;
            } else if (semVerLabel === "minor") {
                version.minor++;
                version.patch = 0;
            } else {
                version.patch++;
            }

            if (prNumber) totalPRs++;
        })
    );

    const daysSinceFirstChange = firstChangeDate ? Math.floor((Date.now() - firstChangeDate) / (1000 * 60 * 60 * 24)) : null;
    const daysSinceLastChange = lastChangeDate ? Math.floor((Date.now() - lastChangeDate) / (1000 * 60 * 60 * 24)) : null;

    const result = {
        baseBranch,
        version,
        currentBranch,
        totalCommits: commits.length,
        totalPRs,
        daysSinceFirstChange,
        daysSinceLastChange,
        totalContributors: Object.keys(contributorStats).length,
        contributors: Object.keys(contributorStats).map(user => ({ username: user, contributions: contributorStats[user].count, names: contributorStats[user].names })),
        changelog,
    };

    if (includeFiles) {
        result["totalFilesChanged"] = filesChanged.size;
    }
    result.contributors = sortContributorsByContributions(result.contributors);
    

    saveToFile(result, `changelog_${baseBranch}_to_${currentBranch}.json`, outputDir);
    saveToFile(result, "changelog.json", outputDir);
    console.log("Changelog generated successfully.");
}

function sortContributorsByContributions(contributors) {
    return contributors.sort((a, b) => b.contributions - a.contributions);
}

function saveToFile(data, fileName, outputDir) {
    try {
        const filePath = path.join(outputDir, fileName);
        fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf-8');
        console.log(`Saved: ${filePath}`);
    } catch (error) {
        console.error(`Error writing file ${fileName}:`, error.message);
    }
}

// Function to extract PR numbers from a commit message (e.g., "Merge pull request #XYZ")
function extractPRNumberFromCommitMessage(commitMessage) {
    const match = commitMessage.match(/Merge pull request #(\d+)/);
    return match ? parseInt(match[1], 10) : null;
}

function getSemVerLabel(message) {
    const matches = message.match(/#(major|minor|patch)/gi);
    return matches ? matches.pop().replace('#', '').toLowerCase() : 'patch';
}

// Main function
(async function main() {
    const args = process.argv.slice(2);
    const outputDir = args[0] || __dirname;
    await setBaseBranch();
    console.log(`Generating changelog in: ${outputDir}`);
    await generateChangelog(outputDir);
})();
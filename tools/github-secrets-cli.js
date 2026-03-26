#!/usr/bin/env node

const fs = require('fs');
const https = require('https');
const { fetchGitHubPublicKey, getKeyId, encryptValue } = require('./githubPublicKey');

const isProduction = process.env.NODE_ENV === 'production';
const DEBUG = process.env.DEBUG === 'true' || !isProduction;

function logDebug(message) {
    if (DEBUG) {
        console.log(`[DEBUG] ${message}`);
    }
}

function parseEnvFile(filePath) {
    const envVars = {};
    try {
        logDebug(`Reading environment file: ${filePath}`);
        const data = fs.readFileSync(filePath, 'utf8');
        const lines = data.split('\n');

        for (let line of lines) {
            line = line.trim();
            if (!line || line.startsWith('#')) continue;

            const idx = line.indexOf('=');
            if (idx === -1) continue;

            const key = line.substring(0, idx).trim();
            const value = line.substring(idx + 1).trim();

            if (key) {
                envVars[key] = value;
                logDebug(`Parsed: ${key}=${value.length > 0 ? '*****' : '(empty)'}`);
            }
        }
    } catch (error) {
        console.error(`Error reading file: ${error.message}`);
        process.exit(1);
    }
    return envVars;
}

function sendSecret(owner, repo, secretName, encryptedValue, token, keyId) {
    logDebug(`Preparing to send encrypted secret: ${secretName}`);
    const options = {
        hostname: 'api.github.com',
        path: `/repos/${owner}/${repo}/actions/secrets/${secretName}`,
        method: 'PUT',
        headers: {
            'Accept': 'application/vnd.github+json',
            'Authorization': `Bearer ${token}`,
            'X-GitHub-Api-Version': '2022-11-28',
            'User-Agent': 'blazium-games/blazium ci/cd cli v0.0.1'
        }
    };

    const payload = JSON.stringify({
        encrypted_value: encryptedValue,
        key_id: keyId
    });

    logDebug(`Sending request to GitHub API: ${options.hostname}${options.path}`);
    logDebug(`Payload: ${JSON.stringify({ encrypted_value: '*****', key_id: keyId })}`);

    const req = https.request(options, res => {
        let responseData = '';
        res.on('data', chunk => { responseData += chunk; });
        res.on('end', () => {
            logDebug(`GitHub API response: ${res.statusCode} ${responseData}`);

            if (res.statusCode === 201 || res.statusCode === 204) {
                console.log(`Successfully set secret: ${secretName}`);
            } else {
                console.error(`Failed to set secret: ${secretName}. Response: ${responseData}`);
            }
        });
    });

    req.on('error', err => {
        console.error(`Request error: ${err.message}`);
    });

    req.write(payload);
    req.end();
}

async function main() {
    const args = process.argv.slice(2);
    let envFile;

    for (let i = 0; i < args.length; i++) {
        if (args[i] === '--env-file' && args[i + 1]) envFile = args[i + 1];
    }

    const token = process.env.GITHUB_TOKEN;
    const owner = process.env.GITHUB_OWNER;
    const repo = process.env.GITHUB_REPO;

    logDebug(`Environment Variables:
      NODE_ENV=${process.env.NODE_ENV || '(not set)'}
      GITHUB_OWNER=${owner}
      GITHUB_REPO=${repo}
      GITHUB_TOKEN=${token ? '*****' : '(missing)'}
      DEBUG=${DEBUG}
    `);

    if (!envFile || !token || !owner || !repo) {
        console.error('Usage: github-secrets-cli --env-file <path>');
        console.error('Environment variables required: GITHUB_TOKEN, GITHUB_OWNER, GITHUB_REPO');
        process.exit(1);
    }

    await fetchGitHubPublicKey(owner, repo, token);
    const keyId = getKeyId();

    if (!keyId) {
        console.error('Failed to retrieve key_id from stored public key.');
        process.exit(1);
    }

    const secrets = parseEnvFile(envFile);

    for (const [key, value] of Object.entries(secrets)) {
        const encryptedValue = await encryptValue(value);
        sendSecret(owner, repo, key, encryptedValue, token, keyId);
    }
}

main();

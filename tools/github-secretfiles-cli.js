#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const https = require('https');
const { fetchGitHubPublicKey, getKeyId, encryptValue } = require('./githubPublicKey');

const SECRET_FOLDER = 'secret_files';

const isProduction = process.env.NODE_ENV === 'production';
const DEBUG = process.env.DEBUG === 'true' || !isProduction;

function logDebug(message) {
    if (DEBUG) {
        console.log(`[DEBUG] ${message}`);
    }
}

function readSecretsFile(filePath) {
    try {
        logDebug(`Reading secrets file: ${filePath}`);
        const data = fs.readFileSync(filePath, 'utf8');
        return JSON.parse(data);
    } catch (error) {
        console.error(`Error reading secrets file: ${error.message}`);
        process.exit(1);
    }
}

function readAndProcessFile(filename, base64) {
    const filePath = path.join(SECRET_FOLDER, filename);
    if (!fs.existsSync(filePath)) {
        console.error(`File not found: ${filePath}`);
        process.exit(1);
    }

    try {
        logDebug(`Reading file: ${filePath}`);
        let content = fs.readFileSync(filePath, 'utf8');

        if (base64) {
            content = Buffer.from(content).toString('base64');
            logDebug(`Encoded ${filename} to Base64`);
        }

        return content;
    } catch (error) {
        console.error(`Error reading file ${filename}: ${error.message}`);
        process.exit(1);
    }
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
            'User-Agent': 'Node.js-CLI'
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
    let secretsFile;

    for (let i = 0; i < args.length; i++) {
        if (args[i] === '--secrets-file' && args[i + 1]) secretsFile = args[i + 1];
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

    if (!secretsFile || !token || !owner || !repo) {
        console.error('Usage: github-secrets-cli --secrets-file <path>');
        console.error('Environment variables required: GITHUB_TOKEN, GITHUB_OWNER, GITHUB_REPO');
        process.exit(1);
    }

    await fetchGitHubPublicKey(owner, repo, token);
    const keyId = getKeyId();

    if (!keyId) {
        console.error('Failed to retrieve key_id from stored public key.');
        process.exit(1);
    }

    const secrets = readSecretsFile(secretsFile);

    if (!Array.isArray(secrets.files)) {
        console.error('Invalid secrets.json format: "files" must be an array.');
        process.exit(1);
    }

    for (const secret of secrets.files) {
        if (!secret.filename || !secret.secret_name || typeof secret.base_64 !== 'boolean') {
            console.error('Each secret must have "filename", "secret_name", and "base_64".');
            process.exit(1);
        }

        const fileContent = readAndProcessFile(secret.filename, secret.base_64);
        const encryptedValue = await encryptValue(fileContent);

        sendSecret(owner, repo, secret.secret_name, encryptedValue, token, keyId);
    }
}

main();

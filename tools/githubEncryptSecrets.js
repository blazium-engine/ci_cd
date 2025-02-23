const fs = require('fs');
const path = require('path');
const https = require('https');
const sodium = require('libsodium-wrappers');

const CONFIG_FOLDER = 'config_files';
const PUBLIC_KEY_FILE = path.join(CONFIG_FOLDER, 'github_public_key.json');

if (!fs.existsSync(CONFIG_FOLDER)) {
    fs.mkdirSync(CONFIG_FOLDER, { recursive: true });
}

function fetchGitHubPublicKey(owner, repo, token) {
    return new Promise((resolve, reject) => {
        if (fs.existsSync(PUBLIC_KEY_FILE)) {
            console.log(`Public key already exists at ${PUBLIC_KEY_FILE}`);
            return resolve(JSON.parse(fs.readFileSync(PUBLIC_KEY_FILE, 'utf8')));
        }

        console.log(`Fetching public key from GitHub...`);
        const options = {
            hostname: 'api.github.com',
            path: `/repos/${owner}/${repo}/actions/secrets/public-key`,
            method: 'GET',
            headers: {
                'Accept': 'application/vnd.github+json',
                'Authorization': `Bearer ${token}`,
                'X-GitHub-Api-Version': '2022-11-28',
                'User-Agent': 'Node.js-CLI'
            }
        };

        https.get(options, res => {
            let data = '';
            res.on('data', chunk => { data += chunk; });
            res.on('end', () => {
                if (res.statusCode !== 200) {
                    return reject(`Failed to fetch public key. Response: ${data}`);
                }

                try {
                    const publicKeyData = JSON.parse(data);
                    fs.writeFileSync(PUBLIC_KEY_FILE, JSON.stringify(publicKeyData, null, 2));
                    console.log(`Public key saved to ${PUBLIC_KEY_FILE}`);
                    resolve(publicKeyData);
                } catch (error) {
                    reject(`Error parsing public key response: ${error.message}`);
                }
            });
        }).on('error', err => reject(`Request error: ${err.message}`));
    });
}

function getKeyId() {
    if (!fs.existsSync(PUBLIC_KEY_FILE)) {
        console.error('Public key file not found. Run fetchGitHubPublicKey first.');
        process.exit(1);
    }

    const publicKeyData = JSON.parse(fs.readFileSync(PUBLIC_KEY_FILE, 'utf8'));
    return publicKeyData.key_id || null;
}

async function encryptValue(value) {
    if (!fs.existsSync(PUBLIC_KEY_FILE)) {
        console.error('Public key file not found. Run fetchGitHubPublicKey first.');
        process.exit(1);
    }

    const publicKeyData = JSON.parse(fs.readFileSync(PUBLIC_KEY_FILE, 'utf8'));
    const publicKeyBase64 = publicKeyData.key;

    await sodium.ready;
    const publicKey = sodium.from_base64(publicKeyBase64, sodium.base64_variants.ORIGINAL);
    const encrypted = sodium.crypto_box_seal(sodium.from_string(value), publicKey);
    return sodium.to_base64(encrypted, sodium.base64_variants.ORIGINAL);
}

module.exports = {
    fetchGitHubPublicKey,
    getKeyId,
    encryptValue
};

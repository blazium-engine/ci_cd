

### **README.md**

```markdown
# GitHub Secrets CLI Tools

This repository contains a set of Node.js CLI tools for managing and encrypting GitHub Actions secrets using GitHub's API.

## **Files**
- `github-secrets-cli.js` – Reads an `.env` file and uploads secrets to GitHub.
- `github-secretfiles-cli.js` – Reads `secrets.json` and uploads file-based secrets.
- `githubEncryptSecrets.js` – Handles encryption of secrets using GitHub's public key.

---

## **1. github-secrets-cli.js**

### **Description**
Uploads secrets from an `.env` file to a GitHub repository. Secrets are encrypted using GitHub's public key before being sent.

### **Usage**
```sh
node github-secrets-cli.js --env-file .env
```

### **Required Environment Variables**
- `GITHUB_TOKEN` – GitHub API token with `repo` and `actions` permissions.
- `GITHUB_OWNER` – Repository owner (organization or username).
- `GITHUB_REPO` – Target repository.

### **Example `.env` File**
```
DATABASE_URL=postgres://user:password@host/dbname
API_KEY=supersecretkey
```

---

## **2. github-secretfiles-cli.js**

### **Description**
Uploads secrets from files listed in a `secrets.json` configuration.

### **Usage**
```sh
node github-secretfiles-cli.js --secrets-file secrets.json
```

### **Required Environment Variables**
- `GITHUB_TOKEN` – GitHub API token with `repo` and `actions` permissions.
- `GITHUB_OWNER` – Repository owner (organization or username).
- `GITHUB_REPO` – Target repository.

### **Example `secrets.json` File**
```json
{
  "files": [
    {
      "filename": "config.json",
      "secret_name": "CONFIG_SECRET",
      "base_64": true
    },
    {
      "filename": "api_key.txt",
      "secret_name": "API_KEY_SECRET",
      "base_64": false
    }
  ]
}
```

### **Folder Structure**
```
project/
│── secret_files/
│   ├── config.json
│   ├── api_key.txt
│── github-secretfiles-cli.js
│── secrets.json
```

---

## **3. githubEncryptSecrets.js**

### **Description**
Handles encryption of secrets using GitHub's public key. Fetches and caches the public key, retrieves the `key_id`, and encrypts values before sending them.

### **Functions**
- `fetchGitHubPublicKey(owner, repo, token)` – Fetches and stores GitHub's public key.
- `getKeyId()` – Retrieves the key ID.
- `encryptValue(value)` – Encrypts a value using `libsodium-wrappers`.

### **Usage**
```javascript
const { fetchGitHubPublicKey, getKeyId, encryptValue } = require('./githubEncryptSecrets');

async function run() {
    const owner = "your-org";
    const repo = "your-repo";
    const token = process.env.GITHUB_TOKEN;

    await fetchGitHubPublicKey(owner, repo, token);
    const keyId = getKeyId();
    const encryptedValue = await encryptValue("my-secret-value");

    console.log(`Encrypted Value: ${encryptedValue}`);
    console.log(`Key ID: ${keyId}`);
}

run();
```

---

## **Installation**
1. Clone the repository:
   ```sh
   git clone https://github.com/your-repo/github-secrets-cli.git
   cd github-secrets-cli
   ```
2. Install dependencies:
   ```sh
   npm install
   ```
3. Set up environment variables:
   ```sh
   export GITHUB_TOKEN="your_personal_access_token"
   export GITHUB_OWNER="your_github_org"
   export GITHUB_REPO="your_repo_name"
   ```
# Deploy to GitHub Pages

## Live URL

After deployment succeeds:

`https://<your-github-username>.github.io/<repo-name>/`

Example: `https://johndoe.github.io/fluter/`

## Firebase (required for live site)

Add your GitHub Pages URL to Firebase:

1. [Firebase Console](https://console.firebase.google.com/) → project **fluter-app-28af9**
2. **Authentication** → **Settings** → **Authorized domains** → add:
   - `<username>.github.io`
3. **Google Cloud Console** → API key → HTTP referrers → add:
   - `https://<username>.github.io/*`

## Enable GitHub Pages (first time)

1. GitHub repo → **Settings** → **Pages**
2. **Build and deployment** → Source: **GitHub Actions**

Pushes to `main` or `master` trigger automatic deploy (~3–5 minutes).

# Getting Started with express-t2s-app-v1

Welcome to **express-t2s-app-v1**, the foundation of your journey toward building a cloud-native, DevOps-ready application using Node.js and Express.

This version sets up a simple web server and introduces you to key concepts like HTTP, Express routing, and serving HTML pages.

---

## What You’ll Learn

- How to run a basic Express.js app locally  
- How the code is structured  
- How to test the app in your browser  
- Basic debugging and port setup

---

## Requirements

Before you start, make sure you have:

| Tool          | How to Install                                                  |
|---------------|-----------------------------------------------------------------|
| **Node.js**   | https://nodejs.org/ (Download and install the LTS version)      |
| **Git**       | https://git-scm.com/downloads                                   |
| **Terminal**  | Use Terminal (Mac/Linux) or PowerShell (Windows)                |
| **VS Code**   | (Recommended) https://code.visualstudio.com/                    |

---

## Folder Structure

Here’s what’s inside this version:

```
express-t2s-app-v1/
├── public/              # Static HTML/CSS files served to the browser
│   └── index.html       # Home page
├── index.js             # Main application file (starts the server)
├── package.json         # Project metadata + dependencies
├── package-lock.json    # Dependency lock file
└── README.md            # Project info
```

---

## Step-by-Step: Run the App Locally

### 1. Open your terminal and navigate to the project folder

```bash
cd express-t2s-app-v1
```

### 2. Install dependencies

This project uses `express`, which is listed in `package.json`. Install it using:

```bash
npm install
```

### 3. Start the server

```bash
node index.js
```

You should see something like:

```
Server is running at http://localhost:3000
```

### 4. View the App in Your Browser

Open your browser and go to:

```
http://localhost:3000
```

---

## What’s Happening in the Code

- `index.js` creates a simple Express web server
- It uses `express.static()` to serve static files (like HTML, CSS) from the `/public` folder
- It listens on port `3000` by default

---

## Common Troubleshooting

| Problem                             | Solution                                                      |
|-------------------------------------|---------------------------------------------------------------|
| `command not found: node`           | Install Node.js properly and restart your terminal            |
| Page not loading                    | Ensure server is running (`node index.js`) and open port 3000 |
| Port 3000 already in use            | Edit `index.js` and change the port to something like `3001`  |

---

## Modify and Experiment

- Try editing `index.html` inside `public/` to change the welcome message.
- Add a new route to `index.js` like `/about`:

```js
app.get('/about', (req, res) => {
  res.send('About this app');
});
```

Then go to `http://localhost:3000/about` in your browser.

---

## Stop the Server

When you’re done:

- Press `Ctrl + C` in your terminal to stop the running server.

---

## Next Steps

Once you're comfortable with this version:

- Move on to `express-t2s-app-v2` to learn how to **Dockerize** this app.
- Each version builds on this foundation to prepare you for modern cloud infrastructure.

---

## Final Notes

You’ve just completed your first Express app! You can now:

- Start simple web projects
- Understand Express routing and static content
- Get comfortable using the terminal and Node.js basics

---

© 2025 Emmanuel Naweji | Transformed 2 Succeed (T2S)

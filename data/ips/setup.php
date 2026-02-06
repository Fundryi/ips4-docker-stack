<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPS4 Docker Stack</title>
    <style>
        :root {
            --primary: #6366f1;
            --primary-dark: #4f46e5;
            --bg: #0f172a;
            --card: #1e293b;
            --border: #334155;
            --text: #f8fafc;
            --text-muted: #94a3b8;
            --success: #22c55e;
            --warning: #f59e0b;
            --info: #3b82f6;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: var(--bg);
            color: var(--text);
            min-height: 100vh;
            line-height: 1.6;
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
            padding: 40px 20px;
        }
        header {
            text-align: center;
            margin-bottom: 48px;
        }
        .logo {
            font-size: 48px;
            margin-bottom: 16px;
        }
        h1 {
            font-size: 32px;
            font-weight: 700;
            margin-bottom: 8px;
            background: linear-gradient(135deg, #6366f1, #8b5cf6);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .subtitle {
            color: var(--text-muted);
            font-size: 16px;
        }
        .alert {
            display: flex;
            align-items: flex-start;
            gap: 12px;
            padding: 16px 20px;
            border-radius: 12px;
            margin-bottom: 24px;
            border: 1px solid;
        }
        .alert-warning {
            background: rgba(245, 158, 11, 0.1);
            border-color: rgba(245, 158, 11, 0.3);
        }
        .alert-info {
            background: rgba(59, 130, 246, 0.1);
            border-color: rgba(59, 130, 246, 0.3);
        }
        .alert-icon { font-size: 20px; flex-shrink: 0; margin-top: 2px; }
        .alert-content { flex: 1; }
        .alert-title { font-weight: 600; margin-bottom: 4px; }
        .alert-warning .alert-title { color: var(--warning); }
        .alert-info .alert-title { color: var(--info); }
        .alert-text { color: var(--text-muted); font-size: 14px; }
        .alert a { color: var(--info); text-decoration: none; font-weight: 500; }
        .alert a:hover { text-decoration: underline; }
        .card {
            background: var(--card);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 32px;
            margin-bottom: 24px;
        }
        .card h2 {
            font-size: 20px;
            font-weight: 600;
            margin-bottom: 24px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .steps { counter-reset: step; }
        .step {
            position: relative;
            padding-left: 48px;
            padding-bottom: 24px;
            border-left: 2px solid var(--border);
            margin-left: 15px;
        }
        .step:last-child { border-left: 2px solid transparent; padding-bottom: 0; }
        .step::before {
            counter-increment: step;
            content: counter(step);
            position: absolute;
            left: -17px;
            top: 0;
            width: 32px;
            height: 32px;
            background: var(--primary);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 600;
            font-size: 14px;
        }
        .step h3 {
            font-size: 16px;
            font-weight: 600;
            margin-bottom: 8px;
        }
        .step p {
            color: var(--text-muted);
            font-size: 14px;
            margin-bottom: 12px;
        }
        code {
            background: rgba(99, 102, 241, 0.15);
            color: #a5b4fc;
            padding: 2px 8px;
            border-radius: 6px;
            font-family: 'SF Mono', Monaco, monospace;
            font-size: 13px;
        }
        pre {
            background: #0d1117;
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 16px;
            overflow-x: auto;
            margin-top: 8px;
        }
        pre code {
            background: none;
            padding: 0;
            color: #e6edf3;
            font-size: 13px;
            line-height: 1.5;
        }
        .config-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 12px;
            font-size: 14px;
        }
        .config-table th,
        .config-table td {
            text-align: left;
            padding: 10px 12px;
            border-bottom: 1px solid var(--border);
        }
        .config-table th {
            color: var(--text-muted);
            font-weight: 500;
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .config-table td:last-child { font-family: 'SF Mono', Monaco, monospace; color: #a5b4fc; }
        .badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 500;
        }
        .badge-success { background: rgba(34, 197, 94, 0.15); color: var(--success); }
        .tech-stack {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            margin-top: 24px;
            padding-top: 24px;
            border-top: 1px solid var(--border);
        }
        .tech {
            background: var(--bg);
            border: 1px solid var(--border);
            padding: 8px 14px;
            border-radius: 8px;
            font-size: 13px;
            color: var(--text-muted);
        }
        footer {
            text-align: center;
            padding: 32px 0;
            color: var(--text-muted);
            font-size: 13px;
        }
        footer a { color: var(--primary); text-decoration: none; }
        footer a:hover { text-decoration: underline; }
        @media (max-width: 640px) {
            .container { padding: 24px 16px; }
            h1 { font-size: 24px; }
            .card { padding: 24px; }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <div class="logo">
                <svg width="56" height="56" viewBox="0 0 24 24" fill="none" stroke="url(#gradient)" stroke-width="1.5">
                    <defs>
                        <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="100%">
                            <stop offset="0%" stop-color="#6366f1"/>
                            <stop offset="100%" stop-color="#8b5cf6"/>
                        </linearGradient>
                    </defs>
                    <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/>
                    <polyline points="7.5 4.21 12 6.81 16.5 4.21"/>
                    <polyline points="7.5 19.79 7.5 14.6 3 12"/>
                    <polyline points="21 12 16.5 14.6 16.5 19.79"/>
                    <polyline points="3.27 6.96 12 12.01 20.73 6.96"/>
                    <line x1="12" y1="22.08" x2="12" y2="12"/>
                </svg>
            </div>
            <h1>IPS4 Docker Stack</h1>
            <p class="subtitle">Production-ready Invision Community deployment</p>
        </header>

        <div class="alert alert-info">
            <span class="alert-icon">&#9432;</span>
            <div class="alert-content">
                <div class="alert-title">Check Requirements</div>
                <div class="alert-text"><a href="ips4.php">Run the server requirements checker</a> before installing IPS4.</div>
            </div>
        </div>

        <div class="alert alert-warning">
            <span class="alert-icon">&#9888;</span>
            <div class="alert-content">
                <div class="alert-title">Setup Required</div>
                <div class="alert-text">Upload your Invision Community files to this directory to begin installation.</div>
            </div>
        </div>

        <div class="card">
            <h2><span>&#128218;</span> Installation Steps</h2>
            <div class="steps">
                <div class="step">
                    <h3>Download IPS4</h3>
                    <p>Get your licensed copy from the <a href="https://invisioncommunity.com/clientarea/" target="_blank" style="color: var(--info)">Invision Community client area</a>.</p>
                </div>
                <div class="step">
                    <h3>Extract Files</h3>
                    <p>Upload all IPS4 files to <code>./data/ips/</code></p>
                    <pre><code>data/ips/
├── index.php
├── applications/
├── system/
└── uploads/</code></pre>
                </div>
                <div class="step">
                    <h3>Configure Environment</h3>
                    <p>Set secure passwords in your <code>.env</code> file:</p>
                    <pre><code>MYSQL_PASSWORD=your_secure_password
MYSQL_ROOT_PASSWORD=your_secure_root_password</code></pre>
                </div>
                <div class="step">
                    <h3>Start Stack</h3>
                    <p>Run from the project root:</p>
                    <pre><code>docker compose up -d</code></pre>
                </div>
                <div class="step">
                    <h3>Enable SSL (Optional)</h3>
                    <p>Set <code>DOMAIN</code> and <code>CERTBOT_EMAIL</code> in <code>.env</code>, then run:</p>
                    <pre><code>./scripts/init-ssl.sh</code></pre>
                    <p>The script reads your domain from <code>.env</code> and sets up Let's Encrypt automatically.</p>
                </div>
                <div class="step">
                    <h3>Run Installer</h3>
                    <p>Open your browser and complete the IPS4 setup wizard.</p>
                    <table class="config-table">
                        <tr><th>Setting</th><th>Value</th></tr>
                        <tr><td>Database Host</td><td>db</td></tr>
                        <tr><td>Database Name</td><td>ips</td></tr>
                        <tr><td>Database User</td><td>ips</td></tr>
                        <tr><td>Password</td><td>Your MYSQL_PASSWORD</td></tr>
                    </table>
                </div>
                <div class="step">
                    <h3>Enable Redis Cache</h3>
                    <p>In AdminCP: <strong>System &gt; Advanced Configuration &gt; Caching</strong></p>
                    <table class="config-table">
                        <tr><th>Setting</th><th>Value</th></tr>
                        <tr><td>Method</td><td>Redis</td></tr>
                        <tr><td>Host</td><td>redis</td></tr>
                        <tr><td>Port</td><td>6379</td></tr>
                    </table>
                </div>
            </div>
        </div>

        <div class="card">
            <h2><span>&#9881;</span> Stack Info</h2>
            <p style="color: var(--text-muted); font-size: 14px; margin-bottom: 16px;">
                Once IPS4 is installed, access this page at <code>/setup.php</code>. Your data persists in <code>./data/</code> directory.
            </p>
            <span class="badge badge-success">
                <span>&#10003;</span> All services running
            </span>
            <div class="tech-stack">
                <span class="tech">Nginx</span>
                <span class="tech">PHP-FPM 8.1</span>
                <span class="tech">MySQL 8.4</span>
                <span class="tech">Redis 7</span>
                <span class="tech">Let's Encrypt</span>
            </div>
        </div>

        <footer>
            <a href="https://github.com" target="_blank">View on GitHub</a> &middot;
            <a href="https://invisioncommunity.com" target="_blank">Invision Community</a>
        </footer>
    </div>
</body>
</html>

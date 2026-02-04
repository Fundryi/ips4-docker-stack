<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPS4 Docker Stack - Setup Required</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            max-width: 800px;
            width: 100%;
            padding: 40px;
        }
        h1 {
            color: #333;
            margin-bottom: 10px;
            font-size: 28px;
        }
        .subtitle {
            color: #666;
            margin-bottom: 30px;
            font-size: 16px;
        }
        .status {
            background: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 15px 20px;
            margin-bottom: 30px;
            border-radius: 4px;
        }
        .status strong {
            color: #856404;
        }
        .steps {
            margin-bottom: 30px;
        }
        .steps h2 {
            color: #444;
            font-size: 20px;
            margin-bottom: 15px;
        }
        .step {
            background: #f8f9fa;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 15px;
            border-left: 4px solid #667eea;
        }
        .step h3 {
            color: #333;
            font-size: 16px;
            margin-bottom: 10px;
        }
        .step p {
            color: #666;
            line-height: 1.6;
            font-size: 14px;
        }
        .step code {
            background: #e9ecef;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: "Courier New", monospace;
            font-size: 13px;
            color: #d63384;
        }
        .step pre {
            background: #2d2d2d;
            color: #f8f8f2;
            padding: 15px;
            border-radius: 6px;
            overflow-x: auto;
            margin-top: 10px;
        }
        .step pre code {
            background: transparent;
            color: #f8f8f2;
            padding: 0;
        }
        .info {
            background: #d1ecf1;
            border-left: 4px solid #17a2b8;
            padding: 15px 20px;
            border-radius: 4px;
        }
        .info strong {
            color: #0c5460;
        }
        .info p {
            color: #0c5460;
            margin-top: 5px;
            font-size: 14px;
            line-height: 1.6;
        }
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            text-align: center;
            color: #999;
            font-size: 13px;
        }
        .checklist {
            list-style: none;
            margin-top: 10px;
        }
        .checklist li {
            padding: 8px 0;
            padding-left: 25px;
            position: relative;
            color: #666;
            font-size: 14px;
        }
        .checklist li:before {
            content: "□";
            position: absolute;
            left: 0;
            color: #667eea;
            font-weight: bold;
        }
        .checklist li.done:before {
            content: "☑";
            color: #28a745;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐳 IPS4 Docker Stack</h1>
        <p class="subtitle">Invision Community 4 - Docker Setup Guide</p>

        <div class="status" style="background: #e7f3ff; border-left-color: #2196f3; margin-bottom: 20px;">
            <strong>🔍 Requirements Checker</strong><br>
            <a href="ips4.php" style="color: #0c5460; text-decoration: underline; font-weight: 500;">Click here to check server requirements</a> before installing IPS4.
        </div>

        <div class="status">
            <strong>⚠️ Setup Required</strong><br>
            This directory is empty. You need to install your Invision Community 4 files here.
        </div>

        <div class="steps">
            <h2>📋 Installation Steps</h2>

            <div class="step">
                <h3>Step 1: Obtain IPS4 Files</h3>
                <p>Download your licensed copy of Invision Community 4.x from the Invision Community client area.</p>
            </div>

            <div class="step">
                <h3>Step 2: Extract Files to This Directory</h3>
                <p>Extract all IPS4 files to this directory (<code>./data/ips/</code>). The directory structure should look like:</p>
                <pre><code>./data/ips/
├── index.php
├── conf_global.php (created during install)
├── applications/
├── core/
├── system/
├── uploads/
└── ... (other IPS4 files)</code></pre>
            </div>

            <div class="step">
                <h3>Step 3: Configure Environment</h3>
                <p>Edit the <code>.env</code> file in the project root and set strong passwords:</p>
                <pre><code>MYSQL_PASSWORD=your_strong_password_here
MYSQL_ROOT_PASSWORD=your_strong_root_password_here
HTTP_PORT=8080</code></pre>
            </div>

            <div class="step">
                <h3>Step 4: Start the Docker Stack</h3>
                <p>From the project root directory, run:</p>
                <pre><code>docker compose up -d --build</code></pre>
            </div>

            <div class="step">
                <h3>Step 5: Access the Installer</h3>
                <p>Open your browser and navigate to:</p>
                <pre><code>http://your-server-ip:8080/</code></pre>
                <p>Use these database settings during installation:</p>
                <ul class="checklist">
                    <li>Database Host: <code>db</code></li>
                    <li>Database Name: <code>ips</code></li>
                    <li>Database User: <code>ips</code></li>
                    <li>Database Password: Value from <code>.env</code> file</li>
                </ul>
            </div>

            <div class="step">
                <h3>Step 6: Enable Redis Caching (Optional)</h3>
                <p>After installation, enable Redis caching in AdminCP:</p>
                <ul class="checklist">
                    <li>Go to <strong>System → Advanced Configuration → Caching</strong></li>
                    <li>Set cache method to <strong>Redis</strong></li>
                    <li>Host: <code>redis</code></li>
                    <li>Port: <code>6379</code></li>
                </ul>
            </div>
        </div>

        <div class="info">
            <strong>ℹ️ Important Notes</strong>
            <p>
                • Delete this file (<code>index.php</code>) after installing IPS4.<br>
                • All your data persists in the <code>./data/</code> directory.<br>
                • You can safely remove and recreate containers without losing data.<br>
                • See <code>README.md</code> for detailed documentation.
            </p>
        </div>

        <div class="footer">
            IPS4 Docker Stack • Powered by Nginx, PHP-FPM 8.1, MySQL 8.4, and Redis 7
        </div>
    </div>

    <?php
    // PHP info for debugging (uncomment if needed)
    // phpinfo();
    ?>
</body>
</html>

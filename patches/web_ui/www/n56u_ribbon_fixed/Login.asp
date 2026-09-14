<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#102a43">
<meta name="robots" content="noindex,nofollow">
<title><#Web_Title#></title>
<link rel="shortcut icon" href="images/favicon.ico">
<link rel="icon" href="images/favicon.png">
<style>
:root {
  color-scheme: light;
  --navy: #102a43;
  --blue: #1677a8;
  --cyan: #27b3b1;
  --ink: #17324d;
  --muted: #6d8295;
  --line: #dbe6ee;
  --paper: #f4f8fb;
  --white: #ffffff;
  --danger: #bd362f;
}
* { box-sizing: border-box; }
html, body { min-height: 100%; }
body {
  margin: 0;
  background: var(--paper);
  color: var(--ink);
  font-family: "Noto Sans", "Source Sans 3", "Segoe UI", sans-serif;
}
.login-shell {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  background: linear-gradient(145deg, #e7f2f7 0%, #f8fbfc 58%, #dbeef0 100%);
}
.login-panel {
  width: min(100%, 420px);
  padding: 42px 38px 34px;
  background: var(--white);
  border: 1px solid rgba(16, 42, 67, .08);
  border-radius: 18px;
  box-shadow: 0 18px 50px rgba(16, 42, 67, .14);
}
.brand-mark {
  width: 52px;
  height: 52px;
  display: grid;
  place-items: center;
  margin-bottom: 22px;
  color: var(--white);
  background: var(--navy);
  border-radius: 14px;
  font-size: 22px;
  font-weight: 700;
  letter-spacing: 0;
}
h1 {
  margin: 0;
  color: var(--navy);
  font-size: 28px;
  line-height: 1.2;
  letter-spacing: 0;
}
.subtitle {
  margin: 10px 0 30px;
  color: var(--muted);
  font-size: 14px;
  line-height: 1.5;
}
.field { margin-bottom: 18px; }
.field label {
  display: block;
  margin-bottom: 8px;
  color: var(--ink);
  font-size: 14px;
  font-weight: 600;
}
.field input {
  width: 100%;
  min-height: 50px;
  padding: 12px 14px;
  color: var(--ink);
  background: #fbfdfe;
  border: 1px solid var(--line);
  border-radius: 10px;
  font: inherit;
  font-size: 16px;
  outline: none;
  transition: border-color .18s ease, box-shadow .18s ease;
}
.field input:focus {
  border-color: var(--cyan);
  box-shadow: 0 0 0 3px rgba(39, 179, 177, .16);
}
.password-wrap { position: relative; }
.password-wrap input { padding-right: 74px; }
.password-toggle {
  position: absolute;
  top: 50%;
  right: 10px;
  min-height: 34px;
  padding: 5px 8px;
  transform: translateY(-50%);
  color: var(--blue);
  background: transparent;
  border: 0;
  border-radius: 6px;
  font: inherit;
  font-size: 13px;
  cursor: pointer;
}
.password-toggle:focus-visible, .submit:focus-visible {
  outline: 3px solid rgba(39, 179, 177, .35);
  outline-offset: 2px;
}
.error {
  display: none;
  margin: 0 0 18px;
  padding: 11px 12px;
  color: var(--danger);
  background: #fff2f0;
  border: 1px solid #f2c5bf;
  border-radius: 9px;
  font-size: 14px;
  line-height: 1.4;
}
.error.visible { display: block; }
.submit {
  width: 100%;
  min-height: 50px;
  margin-top: 4px;
  color: var(--white);
  background: var(--blue);
  border: 0;
  border-radius: 10px;
  font: inherit;
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
  transition: background .18s ease, transform .18s ease;
}
.submit:hover { background: #12658f; }
.submit:active { transform: translateY(1px); }
.footer {
  margin-top: 26px;
  color: var(--muted);
  font-size: 12px;
  text-align: center;
}
@media (max-width: 480px) {
  .login-shell { align-items: flex-start; padding: 18px 14px; }
  .login-panel { margin-top: 8vh; padding: 32px 22px 26px; border-radius: 14px; }
  h1 { font-size: 25px; }
}
</style>
<script>
function initial() {
  var failed = '<% get_parameter("error"); %>' === '1';
  if (failed) {
    document.getElementById("loginError").className = "error visible";
    document.getElementById("password").focus();
  } else {
    document.getElementById("username").focus();
  }
}

function togglePassword() {
  var input = document.getElementById("password");
  var button = document.getElementById("passwordToggle");
  var visible = input.type === "text";
  input.type = visible ? "password" : "text";
  button.innerHTML = visible ? "显示" : "隐藏";
  button.setAttribute("aria-pressed", visible ? "false" : "true");
}
</script>
</head>
<body onload="initial()">
<main class="login-shell">
  <section class="login-panel" aria-labelledby="loginTitle">
    <div class="brand-mark" aria-hidden="true">R</div>
    <h1 id="loginTitle"><#Web_Title#></h1>
    <p class="subtitle">登录路由器管理页面</p>
    <p id="loginError" class="error" role="alert">用户名或密码错误，请重试。</p>
    <form method="post" action="Login.asp" autocomplete="on">
      <div class="field">
        <label for="username"><#menu5_13_username#></label>
        <input id="username" name="username" type="text" autocomplete="username" autocapitalize="none" spellcheck="false" required>
      </div>
      <div class="field">
        <label for="password"><#menu5_13_password#></label>
        <div class="password-wrap">
          <input id="password" name="password" type="password" autocomplete="current-password" required>
          <button id="passwordToggle" class="password-toggle" type="button" onclick="togglePassword()" aria-pressed="false">显示</button>
        </div>
      </div>
      <button class="submit" type="submit"><#Login#></button>
    </form>
    <div class="footer"><#Web_Title#></div>
  </section>
</main>
</body>
</html>

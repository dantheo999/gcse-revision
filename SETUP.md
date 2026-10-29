# GCSE Revision Plan: setup guide

This gets the app online with accounts, syncing between her phone and iPad, and a study group with a friend. It takes 30–60 minutes and costs nothing on the free tiers.

You'll use two free services:

- **Supabase** stores accounts and plans.
- **GitHub Pages** hosts the page so it has a web address: `https://dantheo999.github.io/gcse-revision/`.

## What's in this folder

| File | What it is |
|---|---|
| `index.html` | The app |
| `README.md` | Short overview of the project |
| `config.js` | The only file you edit: your Supabase address and key |
| `supabase/schema.sql` | Sets up the database and its privacy rules (run once) |
| `manifest.webmanifest`, `icon-*.png` | Let it sit on a home screen like an app |

---

## 1. Create the Supabase project

1. Go to **supabase.com** and sign up (GitHub or email).
2. Click **New project**.
   - Name: `gcse-revision`
   - Database password: let it generate one and save it in your password manager. The app never needs it.
   - Region: **West EU (London)**
   - Plan: **Free**
3. Wait a minute or two while it's created.

## 2. Set up the database

1. In the left sidebar, open **SQL Editor** and click **New query**.
2. Open `supabase/schema.sql`, copy everything, paste it in and click **Run**.
3. You should see "Success. No rows returned". If it says something already exists, the script has been run before, so you can carry on.

This creates three tables (plans, profiles, groups) and the rules that keep them private:

- Each person's plan can only be read or changed by that person.
- Group members can see each other's name, tonight's subjects, their weekly count and their streak. Nothing else.
- Nobody can join a group without its invite code.
- Signed-out visitors can't read anything.

## 3. Turn on simple email + password accounts

1. Go to **Authentication → Sign In / Providers** (on some versions it's **Authentication → Providers → Email**).
2. Make sure **Email** is enabled.
3. Turn **Confirm email** **off**, then click **Save**.

Why turn confirmation off: Supabase's built-in email sender only delivers to people on your Supabase team, so confirmation emails would never reach the girls. With it off, they can sign in straight after creating an account. See "Optional: email" below if you want email later.

## 4. Copy your project details into `config.js`

1. Go to **Project Settings → API Keys**. Copy the **publishable** key (starts `sb_publishable_`). If your project only shows legacy keys, copy the **anon public** key instead.
2. Go to **Project Settings → Data API** (or the project's **Connect** button) and copy the **Project URL**, like `https://abcdefghijkl.supabase.co`.
3. Open `config.js` in any text editor and fill in both values:

```js
window.GCSE_CONFIG = {
  supabaseUrl: "https://abcdefghijkl.supabase.co",
  supabaseAnonKey: "sb_publishable_xxxxxxxx"
};
```

This key is designed to be public: it's sent to every visitor's browser. What protects the data is the set of rules from step 2. **Never** put the `secret` or `service_role` key in this file.

## 5. Put it online with GitHub Pages

The code lives in the `dantheo999/gcse-revision` repository.

1. On GitHub, open the repository and go to **Settings → Pages**.
2. Under **Build and deployment**, set **Source** to **Deploy from a branch**, pick **main** and **/ (root)**, then click **Save**.
3. After a minute the page shows "Your site is live at `https://dantheo999.github.io/gcse-revision/`".

Every change pushed to `main` (including editing `config.js` in GitHub's web editor) goes live within a minute or two.

Then go back to Supabase, open **Authentication → URL Configuration**, set **Site URL** to `https://dantheo999.github.io/gcse-revision/` and save.

*Prefer Netlify?* Sign up at app.netlify.com, choose **Add new site → Import an existing project**, and pick this repository. No build settings are needed.

## 6. Set up her devices

On her iPhone and iPad:

1. Open `https://dantheo999.github.io/gcse-revision/` in **Safari**.
2. Tap **Share → Add to Home Screen**. It now opens full-screen like an app, with its own icon.
3. Tap **Create account**, enter her first name, email and a password (8+ characters), and let the phone save the password.
4. On the second device, open the app and **Sign in** with the same details. Ticks and settings now sync between them.
5. Go to **Set up** and check her subjects. The defaults have Foundation Maths and Combined Science on, plus History, Geography and Computer Science. Turn subjects on or off to match what she takes.

## 7. Add her friend

1. Her friend opens the same address on their own phone and creates their own account.
2. One of them opens **Buddies**, types a group name and taps **Create group**. A 6-character invite code appears with a **Copy code** button.
3. They send that code to the other person, who opens **Buddies**, enters it and taps **Join group**.
4. In **Buddies → Together nights**, pick the nights they'll revise together (Tuesday and Thursday by default) and the subjects to line up on. These settings are shared by the whole group.

How together nights work:

- On a together night, both plans make the first session the same subject (for example Science for both).
- Each person gets the topic from their own list, so Foundation and Higher maths each get the right content. If their topic lists match (same board and tier), the topics match too.
- The session steps change to "compare brain dumps" and "quiz each other".
- The rest of each person's plan rebalances around the together nights, so every subject still gets its share.
- Together nights pause during mock weeks, and don't apply on a night someone isn't studying.
- While someone runs the timer, the others see "Studying now" on the Buddies tab and on the session card.

## 8. Close sign-ups once everyone's in

Once both accounts exist, stop strangers creating accounts:

1. Go to **Authentication → Sign In / Providers**.
2. Turn **Allow new users to sign up** off and save.

Turn it back on briefly if another friend joins.

---

## Good to know

- **The free Supabase project pauses after 7 days with no use.** If nobody opens the app for a week (for example over Christmas), the app shows "Offline: saved on this device" and keeps working on each device. To fix it, go to supabase.com, open the project, click **Restore project**, and everything syncs again. No data is lost.
- **Forgotten password:** resetting by email needs email sending set up (below). Until then, make sure each phone saves the password. As a last resort, delete the account under **Authentication → Users** and create it again. This deletes that person's ticks.
- **Deleting someone's data:** delete the user under **Authentication → Users**. Their plan and profile are removed with them.
- **What's stored:** email, first name, plan settings and ticks, and for group members a small summary (tonight's subjects, the week's count, streak, and whether a timer is running). Nothing else. They're 15, so it's worth the friend's parents knowing about the app.
- **Offline:** each device keeps its own copy, so the app works without signal and syncs when it's back online. If the same plan is changed on two devices while both are offline, the most recent change wins.
- **Without a server:** if `config.js` is left empty, the app works on a single device with no accounts, and the Buddies tab explains how to connect it.

## Optional: email (magic links and password resets)

To send real emails (password resets, sign-in links), connect an email provider:

1. Sign up for a provider with a free tier. **Brevo** lets you send from a Gmail address you verify, with no domain needed.
2. In Supabase, go to **Authentication → Emails → SMTP Settings**, turn on custom SMTP and enter the details the provider gives you.

After that you can switch **Confirm email** back on. Ask Claude if you want a "Forgot password?" link added to the sign-in screen.

## Changing the app

All the curriculum content (subjects, topics, weightings, session steps) is in `index.html`, near the top of the script. Each person can also edit their own subjects and topics in **Set up** without touching any code.

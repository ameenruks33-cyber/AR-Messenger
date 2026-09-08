export default function HomePage() {
  return (
    <div className="min-h-screen bg-[#075E54] text-white">
      <header className="mx-auto flex max-w-5xl items-center justify-between px-6 py-6">
        <div className="text-xl font-bold">AR Messenger</div>
        <a href="/login" className="rounded-full bg-white/10 px-4 py-2 text-sm">
          Admin login
        </a>
      </header>
      <main className="mx-auto grid max-w-5xl gap-10 px-6 py-16 lg:grid-cols-2 lg:items-center">
        <div>
          <p className="text-emerald-100">Company messenger + attendance</p>
          <h1 className="mt-3 text-4xl font-extrabold leading-tight md:text-5xl">
            Chat, company workspace, and AR AI in one Android app.
          </h1>
          <p className="mt-5 max-w-xl text-emerald-50">
            Employees sign in with a phone number and PIN, then use chats, communities, status, calls, company tools, and on-device AR AI. Check in only inside an authorized office geofence with a live selfie.
          </p>
          <div className="mt-8 flex flex-wrap gap-3">
            <a
              href="https://ar-messenger.vercel.app/downloads/ar-messenger.apk"
              download="AR-Messenger.apk"
              className="rounded-full bg-[#25D366] px-6 py-3 font-bold text-[#075E54]"
            >
              Download Android APK
            </a>
            <a href="/login" className="rounded-full border border-white/30 px-6 py-3 font-semibold">
              Open admin dashboard
            </a>
          </div>
          <p className="mt-4 text-sm text-emerald-100">
            Android 8+ · Version 1.0.5 · ~64 MB · Phone number + 6-digit PIN. Uninstall the old app before installing this one.
          </p>
          <p className="mt-2 break-all text-xs text-emerald-200">
            Direct file:{' '}
            <a className="underline" href="https://ar-messenger.vercel.app/downloads/ar-messenger.apk">
              https://ar-messenger.vercel.app/downloads/ar-messenger.apk
            </a>
          </p>
        </div>
        <div className="rounded-3xl bg-white/10 p-6 backdrop-blur">
          <h2 className="text-lg font-bold">Install steps</h2>
          <ol className="mt-4 grid gap-3 text-emerald-50">
            <li>1. Tap Download Android APK</li>
            <li>2. Allow install from this browser if Android asks</li>
            <li>3. Open AR Messenger</li>
            <li>4. Enter your mobile number and a 6-digit PIN</li>
            <li>5. Open Company for attendance, tasks, leave, and reports</li>
            <li>6. Tap AR AI to summarize, translate, or create tasks</li>
          </ol>
        </div>
      </main>
    </div>
  );
}

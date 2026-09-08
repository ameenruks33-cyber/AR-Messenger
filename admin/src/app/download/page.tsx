export default function DownloadPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-[#075E54] px-6 text-white">
      <div className="w-full max-w-lg rounded-3xl bg-white/10 p-8 text-center">
        <h1 className="text-3xl font-extrabold">Download AR Messenger</h1>
        <p className="mt-3 text-emerald-100">Android 8+ · Version 1.0.6 · ~64 MB</p>
        <a
          href="https://ar-messenger.vercel.app/downloads/ar-messenger.apk"
          download="AR-Messenger.apk"
          className="mt-8 inline-block rounded-full bg-[#25D366] px-8 py-4 text-lg font-bold text-[#075E54]"
        >
          Download APK
        </a>
        <p className="mt-6 break-all text-xs text-emerald-200">
          https://ar-messenger.vercel.app/downloads/ar-messenger.apk
        </p>
      </div>
    </div>
  );
}

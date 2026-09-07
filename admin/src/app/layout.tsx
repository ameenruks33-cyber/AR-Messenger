import type { Metadata } from "next";
import "./globals.css";
import Shell from "../components/Shell";

export const metadata: Metadata = {
  title: "AR Messenger Admin",
  description: "Company attendance and employee administration",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en">
      <body className="min-h-screen antialiased">
        <Shell>{children}</Shell>
      </body>
    </html>
  );
}

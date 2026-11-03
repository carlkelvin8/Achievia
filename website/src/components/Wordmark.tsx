/** "Achie" + "via" two-tone wordmark, matching the login screen of the Achievia app. */
export default function Wordmark({ className = "" }: { className?: string }) {
  return (
    <span className={`wordmark ${className}`}>
      <span className="wm-a">Achie</span>
      <span className="wm-b">via</span>
    </span>
  );
}

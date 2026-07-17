const BulletIcon = (props) => (
  <svg
    viewBox="0 0 64 64"
    xmlns="http://www.w3.org/2000/svg"
    width="100%"
    height="100%"
    fill="none"
    {...props}
  >
    <path
      d="M18 58V20.5L32 6l14 14.5V58H18Z"
      stroke="currentColor"
      strokeWidth="3"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
    <path
      d="M18 20.5h28M32 6v52M18 58l14-14 14 14M18 20.5l14 23.5 14-23.5"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
    <path
      d="M24 20.5 32 6l8 14.5M24 58V20.5M40 58V20.5"
      stroke="currentColor"
      strokeWidth="1.6"
      strokeLinecap="round"
      strokeLinejoin="round"
      opacity="0.55"
    />
  </svg>
);

export default BulletIcon;

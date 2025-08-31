// Deploy script for Mainnet - deploy-mainnet.ts
const { execSync } = require("child_process");

try {
  console.log("Deploying to mainnet via clarinet...");
  execSync("clarinet deploy --config clarinet-mainnet-config.toml", { stdio: "inherit" });
  console.log("Deployment completed.");
} catch (e) {
  console.error(e);
  process.exit(1);
}

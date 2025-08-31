// Deploy script for Testnet - deploy-testnet.ts
// Note: This script assumes Clarinet or similar toolchain. It is an example using clarinet CLI via shell.

const { execSync } = require("child_process");

try {
  console.log("Deploying to testnet via clarinet (simnet deployment)...");
  execSync("clarinet deploy --config clarinet-testnet-config.toml", { stdio: "inherit" });
  console.log("Deployment completed.");
} catch (e) {
  console.error(e);
  process.exit(1);
}

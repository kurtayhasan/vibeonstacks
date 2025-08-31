// initialize-contracts.ts
// Example script to set admin and initial state after deployment using clarinet or direct contract calls.

const { execSync } = require("child_process");

try {
  console.log("Initializing contracts...");
  execSync("clarinet call-function main-contract initialize \"\" --from wallet_1", { stdio: "inherit" });
  console.log("Initialization completed.");
} catch (e) {
  console.error(e);
  process.exit(1);
}

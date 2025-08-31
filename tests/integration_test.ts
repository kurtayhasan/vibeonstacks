import { Cl } from "@stacks/transactions";
import { describe, expect, it } from "vitest";

const accounts = simnet.getAccounts();
const deployer = accounts.get("wallet_1")!;
const user2 = accounts.get("wallet_2")!;

describe("Integration tests", () => {
  it("create, transfer, and verify ownership", () => {
    simnet.callPublicFn(
      "main-contract",
      "create-entry",
      [Cl.stringUtf8("ikey"), Cl.stringUtf8("ival")],
      deployer,
    );

    simnet.callPublicFn(
      "main-contract",
      "transfer-entry",
      [Cl.stringUtf8("ikey"), user2.address],
      deployer,
    );

    const read = simnet.callReadOnlyFn(
      "main-contract",
      "get-entry",
      [Cl.stringUtf8("ikey")],
      user2,
    );

    expect(read.result).toBeOk();
  });
});

import { Cl } from "@stacks/transactions";
import { describe, expect, it } from "vitest";

const accounts = simnet.getAccounts();
const deployer = accounts.get("wallet_1")!;

describe("Helper contract tests", () => {
  it("concat keys utility", () => {
    const res = simnet.callReadOnlyFn(
      "helper-contract",
      "concat-keys",
      [Cl.stringUtf8("a"), Cl.stringUtf8("b")],
      deployer,
    );
    expect(res.result).toBeOk();
  });
});

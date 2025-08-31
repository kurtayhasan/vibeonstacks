import { Cl } from "@stacks/transactions";
import { describe, expect, it } from "vitest";

const accounts = simnet.getAccounts();
const deployer = accounts.get("wallet_1")!;
const user2 = accounts.get("wallet_2")!;
const user3 = accounts.get("wallet_3")!;

describe("main-contract.clar - comprehensive unit tests", () => {
  it("create entry and read fields (version & frozen)", () => {
    const tx = simnet.callPublicFn(
      "main-contract",
      "create-entry",
      [Cl.stringUtf8("hotline:region1"), Cl.stringUtf8("tel:123-456")],
      deployer,
    );
    expect(tx.result).toBeOk(true);

    const read = simnet.callReadOnlyFn(
      "main-contract",
      "get-entry",
      [Cl.stringUtf8("hotline:region1")],
      deployer,
    );
    expect(read.result).toBeOk();
    const entry = read.result.value;
    // entry tuple shape: (owner value created updated version frozen)
    expect(entry).toHaveLength(6);
    // version should be 1 and frozen false
    expect(entry[4].value).toBe(1n);
    expect(entry[5].value).toBe(false);
  });

  it("non-owner cannot update or delete", () => {
    const upd = simnet.callPublicFn(
      "main-contract",
      "update-entry",
      [Cl.stringUtf8("hotline:region1"), Cl.stringUtf8("tel:000")],
      user2,
    );
    expect(upd.result).toBeErr();

    const del = simnet.callPublicFn(
      "main-contract",
      "delete-entry",
      [Cl.stringUtf8("hotline:region1")],
      user2,
    );
    expect(del.result).toBeErr();
  });

  it("owner updates bump version and can transfer ownership", () => {
    const upd = simnet.callPublicFn(
      "main-contract",
      "update-entry",
      [Cl.stringUtf8("hotline:region1"), Cl.stringUtf8("tel:999")],
      deployer,
    );
    expect(upd.result).toBeOk(true);

    const read = simnet.callReadOnlyFn(
      "main-contract",
      "get-entry",
      [Cl.stringUtf8("hotline:region1")],
      deployer,
    );
    expect(read.result).toBeOk();
    const entry = read.result.value;
    // version should be 2 after update
    expect(entry[4].value).toBe(2n);

    // transfer to user2
    const tx = simnet.callPublicFn(
      "main-contract",
      "transfer-entry",
      [Cl.stringUtf8("hotline:region1"), Cl.principal(user2.address)],
      deployer,
    );
    expect(tx.result).toBeOk(true);

    // now user2 should be able to update
    const upd2 = simnet.callPublicFn(
      "main-contract",
      "update-entry",
      [Cl.stringUtf8("hotline:region1"), Cl.stringUtf8("tel:888")],
      user2,
    );
    expect(upd2.result).toBeOk(true);
  });

  it("owner-key listing and pagination pattern", () => {
    // create multiple keys for user3
    for (let i = 0; i < 3; i++) {
      const k = `resource:${i}`;
      const tx = simnet.callPublicFn(
        "main-contract",
        "create-entry",
        [Cl.stringUtf8(k), Cl.stringUtf8("link")],
        user3,
      );
      expect(tx.result).toBeOk(true);
    }

    const cnt = simnet.callReadOnlyFn(
      "main-contract",
      "get-key-count",
      [Cl.principal(user3.address)],
      user3,
    );
    expect(cnt.result).toBeOk();
    expect(cnt.result.value).toBe(3n);

    // iterate keys by index
    for (let i = 0; i < 3; i++) {
      const res = simnet.callReadOnlyFn(
        "main-contract",
        "get-key-by-owner",
        [Cl.principal(user3.address), Cl.uint(i)],
        user3,
      );
      expect(res.result).toBeOk();
    }
  });

  it("admin pause prevents new creates", () => {
    // deployer is admin by default
    const p = simnet.callPublicFn(
      "main-contract",
      "set-paused",
      [Cl.bool(true)],
      deployer,
    );
    expect(p.result).toBeOk(true);

    const tx = simnet.callPublicFn(
      "main-contract",
      "create-entry",
      [Cl.stringUtf8("hotline:region2"), Cl.stringUtf8("tel:111")],
      user2,
    );
    expect(tx.result).toBeErr();

    // unpause
    const up = simnet.callPublicFn(
      "main-contract",
      "set-paused",
      [Cl.bool(false)],
      deployer,
    );
    expect(up.result).toBeOk(true);
  });

  it("moderator freeze blocks updates/transfers/deletes", () => {
    // add user2 as moderator
    const add = simnet.callPublicFn(
      "main-contract",
      "add-moderator",
      [Cl.principal(user2.address)],
      deployer,
    );
    expect(add.result).toBeOk(true);

    // create a key owned by user3
    const tx = simnet.callPublicFn(
      "main-contract",
      "create-entry",
      [Cl.stringUtf8("counselor:slot:2025010109"), Cl.stringUtf8("available")],
      user3,
    );
    expect(tx.result).toBeOk(true);

    // moderator freeze the key
    const freeze = simnet.callPublicFn(
      "main-contract",
      "set-key-frozen",
      [Cl.stringUtf8("counselor:slot:2025010109"), Cl.bool(true)],
      user2,
    );
    expect(freeze.result).toBeOk(true);

    // owner cannot update/delete/transfer
    const upd = simnet.callPublicFn(
      "main-contract",
      "update-entry",
      [Cl.stringUtf8("counselor:slot:2025010109"), Cl.stringUtf8("busy")],
      user3,
    );
    expect(upd.result).toBeErr();

    const del = simnet.callPublicFn(
      "main-contract",
      "delete-entry",
      [Cl.stringUtf8("counselor:slot:2025010109")],
      user3,
    );
    expect(del.result).toBeErr();

    const transfer = simnet.callPublicFn(
      "main-contract",
      "transfer-entry",
      [Cl.stringUtf8("counselor:slot:2025010109"), Cl.principal(deployer.address)],
      user3,
    );
    expect(transfer.result).toBeErr();

    // unfreeze
    const unf = simnet.callPublicFn(
      "main-contract",
      "set-key-frozen",
      [Cl.stringUtf8("counselor:slot:2025010109"), Cl.bool(false)],
      user2,
    );
    expect(unf.result).toBeOk(true);
  });

  it("rejects empty keys and enforces value length (edge cases)", () => {
    const badKey = simnet.callPublicFn(
      "main-contract",
      "create-entry",
      [Cl.stringUtf8(""), Cl.stringUtf8("x")],
      deployer,
    );
    expect(badKey.result).toBeErr();
  });
});

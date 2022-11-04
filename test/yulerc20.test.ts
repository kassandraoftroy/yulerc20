import { expect } from "chai";
import hre = require("hardhat");
import { Contract, Signer, Wallet } from "ethers";
import {
  OpenZeppelinERC20,
  SolmateERC20,
  YulERC20,
  YulERC20External,
} from "../typechain";
import { keccak256 } from "@ethersproject/keccak256";
import { ecsign } from "ethereumjs-util";

const { ethers, deployments } = hre;

function hexToBytes(hexString: string) {
  if (hexString.length % 2 !== 0) {
    throw "Must have an even number of hex digits to convert to bytes";
  }
  const numBytes = hexString.length / 2;
  const byteArray = new Uint8Array(numBytes);
  for (let i = 0; i < numBytes; i++) {
    byteArray[i] = parseInt(hexString.substring(i * 2, i * 2 + 2), 16);
  }
  return byteArray;
}

const sign = (msgHash: string, privKey: string): any => {
  const hash = Buffer.alloc(32, msgHash.slice(2), "hex");
  const priv = Buffer.alloc(32, privKey.slice(2), "hex");
  return ecsign(hash, priv);
};

describe("YulERC20 test", async function () {
  this.timeout(0);

  let user: Signer;
  let user2: Signer;
  let ozToken: OpenZeppelinERC20;
  let smToken: SolmateERC20;
  let yulToken: YulERC20;
  let yulToken2: YulERC20External;

  beforeEach("setup", async function () {
    if (hre.network.name !== "hardhat") {
      console.error("Test Suite is meant to be run on hardhat only");
      process.exit(1);
    }

    [user, user2] = await ethers.getSigners();

    await deployments.fixture();
    ozToken = (await ethers.getContract(
      "OpenZeppelinERC20",
      user
    )) as OpenZeppelinERC20;
    smToken = (await ethers.getContract("SolmateERC20", user)) as SolmateERC20;
    yulToken = (await ethers.getContract("YulERC20", user)) as YulERC20;
    yulToken2 = (await ethers.getContract(
      "YulERC20External",
      user
    )) as YulERC20External;
  });
  it("tests erc20", async function () {
    const oneEth = ethers.utils.parseEther("1");
    const tokens = [ozToken, smToken, yulToken, yulToken2];
    for (let i = 0; i < tokens.length; i++) {
      const decimals = await tokens[i].decimals();
      expect(decimals).to.be.equal(18);
      const name = await tokens[i].name();
      expect(name).to.be.equal("abc");
      const symbol = await tokens[i].symbol();
      expect(symbol).to.be.equal("ABC");
      const bal = await tokens[i].balanceOf(await user.getAddress());
      const supply = await tokens[i].totalSupply();
      expect(bal).to.be.equal(supply);
      const receiverBal = await tokens[i].balanceOf(await user2.getAddress());
      expect(receiverBal).to.be.equal(ethers.constants.Zero);
      const tx = await tokens[i].transfer(await user2.getAddress(), oneEth);
      const rc = await tx.wait();
      const balAfter = await tokens[i].balanceOf(await user.getAddress());
      const receiverBalAfter = await tokens[i].balanceOf(
        await user2.getAddress()
      );
      expect(receiverBalAfter).to.be.gt(receiverBal);
      expect(balAfter).to.be.lt(bal);
      expect(balAfter).to.be.equal(bal.sub(oneEth));
      expect(receiverBalAfter).to.be.equal(receiverBal.add(oneEth));
      expect(receiverBalAfter.add(balAfter)).to.be.equal(supply);
      const event = rc?.events?.find(
        (event: any) => event.event === "Transfer"
      );
      // eslint-disable-next-line no-unsafe-optional-chaining
      expect(event?.address).to.be.equal(tokens[i].address);

      await expect(
        tokens[i].transfer(
          await user2.getAddress(),
          balAfter.add(ethers.constants.One)
        )
      ).to.be.reverted;

      const allowanceBefore = await tokens[i].allowance(
        await user2.getAddress(),
        await user.getAddress()
      );
      expect(allowanceBefore).to.be.eq(ethers.constants.Zero);
      await expect(
        tokens[i].transferFrom(
          await user2.getAddress(),
          await user.getAddress(),
          ethers.constants.One
        )
      ).to.be.reverted;

      const tx2 = await tokens[i]
        .connect(user2)
        .approve(await user.getAddress(), receiverBalAfter);
      const rc2 = await tx2.wait();
      const allowanceAfter = await tokens[i].allowance(
        await user2.getAddress(),
        await user.getAddress()
      );
      expect(allowanceAfter).to.be.gt(allowanceBefore);
      expect(allowanceAfter).to.be.equal(receiverBalAfter);

      const event2 = rc2?.events?.find(
        (event: any) => event.event === "Approval"
      );
      // eslint-disable-next-line no-unsafe-optional-chaining
      expect(event2?.address).to.be.equal(tokens[i].address);

      const tx3 = await tokens[i].transferFrom(
        await user2.getAddress(),
        await user.getAddress(),
        receiverBalAfter
      );
      const rc3 = await tx3.wait();
      const balEnd = await tokens[i].balanceOf(await user.getAddress());
      const receiverBalEnd = await tokens[i].balanceOf(
        await user2.getAddress()
      );
      expect(balEnd).to.be.equal(bal);
      expect(receiverBalEnd).to.be.equal(receiverBal);

      const event3 = rc3?.events?.find(
        (event: any) => event.event === "Transfer"
      );
      // eslint-disable-next-line no-unsafe-optional-chaining
      expect(event3?.address).to.be.equal(tokens[i].address);

      // solmate does not protect against transfers to address(0) so we skip this check there
      if (tokens[i].address != smToken.address) {
        await expect(
          tokens[i].connect(user).transfer(ethers.constants.AddressZero, oneEth)
        ).to.be.reverted;

        await expect(
          tokens[i].connect(user).mint(ethers.constants.AddressZero, oneEth)
        ).to.be.reverted;
      }

      const hugeNumber = ethers.BigNumber.from(
        "0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0"
      );
      await expect(
        tokens[i].connect(user).mint(await user2.getAddress(), hugeNumber)
      ).to.be.reverted;
      await expect(
        tokens[i].connect(user2).mint(await user2.getAddress(), oneEth)
      ).to.be.reverted;
      await tokens[i].connect(user).mint(await user2.getAddress(), oneEth);
      const balCheck = await tokens[i].balanceOf(await user.getAddress());
      const receiverBalCheck = await tokens[i].balanceOf(
        await user2.getAddress()
      );
      expect(balCheck).to.be.equal(balEnd);
      expect(receiverBalEnd).to.be.lt(receiverBalCheck);
      expect(receiverBalEnd.add(oneEth)).to.be.equal(receiverBalCheck);

      const newSupply = await tokens[i].totalSupply();
      expect(supply).to.be.lt(newSupply);
      expect(supply.add(oneEth)).to.be.equal(newSupply);

      await expect(tokens[i].connect(user2).burn(supply)).to.be.reverted;
      await tokens[i].connect(user2).burn(receiverBalCheck);

      const bal0 = await tokens[i].balanceOf(user2.getAddress());
      expect(bal0).to.equal(ethers.constants.Zero);

      const supplyCheck = await tokens[i].totalSupply();
      expect(supplyCheck).to.be.lt(newSupply);
      expect(supplyCheck.add(receiverBalCheck)).to.be.equal(newSupply);

      const itoken: Contract = await ethers.getContractAt(
        [
          "function balanceOf(address) external returns (uint256)",
          "function allowance(address, address) external returns (uint256)",
          "function totalSupply() external returns (uint256)",
          "function name() external returns (string memory)",
          "function symbol() external returns (string memory)",
          "function decimals() external returns (uint8)",
        ],
        tokens[i].address,
        user
      );
      await itoken.balanceOf(await user.getAddress());
      await itoken.allowance(await user.getAddress(), await user2.getAddress());
      await itoken.totalSupply();
      await itoken.name();
      await itoken.symbol();
      await itoken.decimals();
    }

    const permitTokens = [smToken, yulToken, yulToken2];

    for (let j = 0; j < permitTokens.length; j++) {
      const random = new Wallet(
        "0x36383cc9cfbf1dc87c78c2529ae2fcd4e3fc4e575e154b357ae3a8b2739113cf"
      );
      await permitTokens[j].connect(user).transfer(random.address, oneEth);

      const ds = await permitTokens[j].DOMAIN_SEPARATOR();

      const z = ethers.utils.defaultAbiCoder.encode(
        ["bytes32", "address", "address", "uint256", "uint256", "uint256"],
        [
          "0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9",
          random.address,
          await user.getAddress(),
          oneEth,
          ethers.constants.Zero,
          9999999999,
        ]
      );
      const innerHash = keccak256(hexToBytes(z.substring(2)));

      const outerString = ethers.utils.solidityPack(
        ["string", "bytes32", "bytes32"],
        ["\x19\x01", ds, innerHash]
      );
      const hashOut = keccak256(hexToBytes(outerString.substring(2)));

      const sig = sign(
        hashOut,
        "0x36383cc9cfbf1dc87c78c2529ae2fcd4e3fc4e575e154b357ae3a8b2739113cf"
      );
      const allowanceBefore = await permitTokens[j].allowance(
        random.address,
        await user.getAddress()
      );
      expect(allowanceBefore).to.be.equal(ethers.constants.Zero);
      const tx = await permitTokens[j].permit(
        random.address,
        await user.getAddress(),
        oneEth,
        9999999999,
        sig.v,
        sig.r,
        sig.s
      );
      const rc = await tx.wait();
      const event2 = rc?.events?.find(
        (event: any) => event.event === "Approval"
      );
      // eslint-disable-next-line no-unsafe-optional-chaining
      expect(event2?.address).to.be.equal(permitTokens[j].address);
      const allowanceAfter = await permitTokens[j].allowance(
        random.address,
        await user.getAddress()
      );
      expect(allowanceAfter).to.be.gt(allowanceBefore);
      expect(allowanceAfter).to.be.equal(oneEth);

      await expect(
        permitTokens[j].permit(
          random.address,
          await user2.getAddress(),
          oneEth,
          9999999999,
          sig.v,
          sig.r,
          sig.s
        )
      ).to.be.reverted;
    }
  });
});

import { expect } from "chai";
import hre = require("hardhat");
import { Signer } from "ethers";
import { OpenZeppelinERC20, SolmateERC20, YulERC20 } from "../typechain";

const { ethers, deployments } = hre;

describe("YulERC20 test", async function () {
  this.timeout(0);

  let user: Signer;
  let user2: Signer;
  let ozToken: OpenZeppelinERC20;
  let smToken: SolmateERC20;
  let yulToken: YulERC20;

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
  });
  it("tests erc20", async function () {
    const oneEth = ethers.utils.parseEther("1");
    const tokens = [ozToken, smToken, yulToken];
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

      // solmate does not protect against transfers to address(0)
      if (tokens[i].address != smToken.address) {
        await expect(
          tokens[i].connect(user).transfer(ethers.constants.AddressZero, oneEth)
        ).to.be.reverted;
      }
    }
  });
});

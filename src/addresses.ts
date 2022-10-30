/* eslint-disable @typescript-eslint/naming-convention */
export interface Addresses {
  WETH: string;
}

export const getAddresses = (network: string): Addresses => {
  switch (network) {
    case "hardhat":
      return {
        WETH: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
      };
    case "mainnet":
      return {
        WETH: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
      };
    case "polygon":
      return {
        WETH: "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619",
      };
    case "optimism":
      return {
        WETH: "0x4200000000000000000000000000000000000006",
      };
    case "goerli":
      return {
        WETH: "",
      };
    default:
      throw new Error(`No addresses for Network: ${network}`);
  }
};

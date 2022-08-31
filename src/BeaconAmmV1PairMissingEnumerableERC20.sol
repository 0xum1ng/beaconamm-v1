// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {BeaconAmmV1PairERC20} from "./BeaconAmmV1PairERC20.sol";
import {BeaconAmmV1PairMissingEnumerable} from "./BeaconAmmV1PairMissingEnumerable.sol";
import {IBeaconAmmV1Factory} from "./IBeaconAmmV1Factory.sol";

contract BeaconAmmV1PairMissingEnumerableERC20 is
    BeaconAmmV1PairMissingEnumerable,
    BeaconAmmV1PairERC20
{
    function pairVariant()
        public
        pure
        override
        returns (IBeaconAmmV1Factory.PairVariant)
    {
        return IBeaconAmmV1Factory.PairVariant.MISSING_ENUMERABLE_ERC20;
    }
}

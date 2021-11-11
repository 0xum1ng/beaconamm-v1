// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ICurve} from "./ICurve.sol";
import {CurveErrorCodes} from "./CurveErrorCodes.sol";
import {PRBMathUD60x18} from "prb-math/PRBMathUD60x18.sol";

/*
@author 0xmons and boredGenius
@notice Bonding curve logic for an exponential curve, where each buy/sell changes spot price by multiplying/dividing delta
*/
contract ExponentialCurve is ICurve, CurveErrorCodes {
    using PRBMathUD60x18 for uint256;

    uint256 public constant MIN_PRICE = 1 gwei;

    function validateDelta(uint256 delta)
        external
        pure
        override
        returns (bool)
    {
        return delta >= PRBMathUD60x18.SCALE;
    }

    function getBuyInfo(
        uint256 spotPrice,
        uint256 delta,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier
    )
        external
        pure
        override
        returns (
            Error error,
            uint256 newSpotPrice,
            uint256 inputValue,
            uint256 protocolFee
        )
    {
        // TODO: should we use delta^(numItems-1) instead?
        uint256 deltaPowN = delta.powu(numItems);
        newSpotPrice = spotPrice.mul(deltaPowN);
        uint256 buySpotPrice = spotPrice.mul(delta);
        // If we buy n items, then the total cost is equal to:
        // buy spot price + (delta*buy spot price) + (delta^2*buy spot price) + ... (delta^(numItems-1)*buy spot price)
        // This is equal to buy spot price*(1-delta^(n-1))/(1-delta))
        // To avoid underflow errors, as delta is always > 1, we simply multiply both the num/denom by -1
        // This gives us buy spot price*(delta^(n-1))/(delta-1)
        inputValue = buySpotPrice.mul(
            (deltaPowN - PRBMathUD60x18.SCALE).div(delta - PRBMathUD60x18.SCALE)
        );
        protocolFee = inputValue.mul(protocolFeeMultiplier);
        inputValue += inputValue.mul(feeMultiplier);
        inputValue += protocolFee;
        error = Error.OK;
    }

    function getSellInfo(
        uint256 spotPrice,
        uint256 delta,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier
    )
        external
        pure
        override
        returns (
            Error error,
            uint256 newSpotPrice,
            uint256 outputValue,
            uint256 protocolFee
        )
    {
        uint256 invDelta = delta.inv();
        uint256 invDeltaPowN = invDelta.powu(numItems);
        newSpotPrice = spotPrice.mul(invDeltaPowN);
        if (newSpotPrice < MIN_PRICE) {
            newSpotPrice = MIN_PRICE;
        }
        outputValue = spotPrice.mul(
            (PRBMathUD60x18.SCALE - invDeltaPowN).div(
                PRBMathUD60x18.SCALE - invDelta
            )
        );
        protocolFee = outputValue.mul(protocolFeeMultiplier);
        outputValue -= outputValue.mul(feeMultiplier);
        outputValue -= protocolFee;
        error = Error.OK;
    }
}

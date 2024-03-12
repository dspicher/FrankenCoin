pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20PermitLight.sol";
import "../Equity.sol";

contract FPSWrapper is ERC20 {

    Equity private immutable fps;

    constructor(Equity fps_) ERC20(18){
        fps = fps_;
    }

    function name() external pure override returns (string memory) {
        return "Wrapped Frankencoin Pool Share";
    }

    function symbol() external pure override returns (string memory) {
        return "WFPS";
    }

    // requires allowance
    function wrap(uint256 amount) public {
        fps.transferFrom(msg.sender, address(this), amount);
        super._mint(msg.sender, amount);
    }

    function unwrap(uint256 amount) internal virtual {
        super._burn(msg.sender, amount);
        fps.transfer(msg.sender, amount);
    }

    /**
     * Sell immediately, bypassing the 90 day holding requirement if the
     * average wrapped token has been around for long enough and no one
     * cancelled the votes of this contract. Can help with market making
     * between chains when this token is bridged.
     * 
     * Anyone can prevent this method from being executable via the
     * halveHoldingDuration function. Also, it won't be executable in an
     * expanding market where the number of wrapped FPS doubles every
     * 90 days such that the average holding period of this contract stays
     * below that duration.
     */
    function unwrapAndSell(uint256 amount) internal virtual {
        super._burn(msg.sender, amount);
        fps.redeem(msg.sender, amount);
    }

    /**
     * Reduces the recorded holding duration of the wrapped FPS. This has two effects:
     * - Averts the risk of this contract accumulating too many votes over time (i.e. 98%)
     * - Can prevent "unwrapAndSell" from succeeding (which can be desired to prevent short
     *   term arbitrage at the cost of all other FPS holders)
     * 
     * Anyone with 2% of the votes can call this.
     */
    function halveHoldingDuration(address[] calldata helpers) public {
        fps.checkQualified(msg.sender, helpers);
        // causes our votes to be cut in half
        fps.transfer(address(this), totalSupply());
    }

}
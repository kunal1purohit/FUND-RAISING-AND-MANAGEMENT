// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract crowdfunding {
    mapping(address => uint256) public contributors;
    address public manager;
    uint256 public target;
    uint256 public mincontro;
    uint256 public deadline;
    uint256 public noofcontro;
    uint256 public raisedamount;

    struct request {
        string description;
        address payable recipient;
        uint256 value;
        uint256 noofvoters;
        bool completed;
        mapping(address => bool) voters;
    }

    mapping(uint256 => request) public requests;
    uint256 public numofrequest;

    constructor(uint256 _target, uint256 _deadline) {
        target = _target;
        deadline = _deadline + block.timestamp;
        manager = msg.sender;
        mincontro = 100 wei;
    }

    function sendeth() public payable {
        require(block.timestamp < deadline, "deadline has passed");
        require(msg.value >= 100 wei, "min contro is not met");
        if (contributors[msg.sender] == 0) {
            noofcontro++;
        }
        contributors[msg.sender] += msg.value;
        raisedamount += msg.value;
    }

    function fetcontractbalance() public view returns (uint256) {
        return address(this).balance;
    }

    function refund() public {
        require(
            block.timestamp >= deadline && raisedamount < target,
            "you are not eligible for refund"
        );
        require(contributors[msg.sender] > 0);
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    modifier onlymanager() {
        require(msg.sender == manager, "only manager can access this function");
        _;
    }

    function createrequest(
        string memory _description,
        address payable _recipient,
        uint256 _value
    ) public onlymanager {
        request storage newrequest = requests[numofrequest];
        numofrequest++;
        newrequest.description = _description;
        newrequest.value = _value;
        newrequest.recipient = _recipient;
        newrequest.completed = false;
        newrequest.noofvoters = 0;
    }

    function voterequest(uint256 requestid) public {
        require(contributors[msg.sender] > 0, "you  ust be a contributor");
        request storage thisrequest = requests[requestid];
        require(
            thisrequest.voters[msg.sender] == false,
            "you have voted already"
        );
        thisrequest.voters[msg.sender] == true;
        thisrequest.noofvoters++;
    }

    function makepaymentofrequest(uint256 requestid) public onlymanager {
        require(raisedamount > target, "we dont have extected target amount");
        request storage thisrequest = requests[requestid];
        require(
            thisrequest.value < raisedamount,
            "your value is too high for us"
        );
        require(
            thisrequest.completed == false,
            "the request have been completed"
        );
        require(
            thisrequest.noofvoters > noofcontro / 2,
            "maximum contributors are not agreed"
        );
        thisrequest.recipient.transfer(thisrequest.value);
        thisrequest.completed = true;
    }
}

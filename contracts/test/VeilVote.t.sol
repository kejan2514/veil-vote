// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {VeilVote} from "../src/VeilVote.sol";

contract VeilVoteTest is Test {
    VeilVote internal ballot;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);
    address internal outsider = address(0xBAD);
    uint256 internal start;
    uint256 internal end;

    function setUp() public {
        start = block.timestamp + 1 days;
        end = start + 3 days;
        ballot = new VeilVote("Fund public goods?", start, end);

        address[] memory voters = new address[](2);
        voters[0] = alice;
        voters[1] = bob;
        ballot.addVoters(voters);
    }

    function test_AdminCanAddEligibleVoters() public view {
        assertTrue(ballot.isEligible(alice));
        assertTrue(ballot.isEligible(bob));
    }

    function test_RevertWhen_NonAdminAddsVoter() public {
        address[] memory voters = new address[](1);
        voters[0] = outsider;
        vm.prank(outsider);
        vm.expectRevert(VeilVote.NotAdmin.selector);
        ballot.addVoters(voters);
    }

    function test_RevertWhen_AddingVotersAfterStart() public {
        vm.warp(start);
        address[] memory voters = new address[](1);
        voters[0] = outsider;
        vm.expectRevert(VeilVote.VotingAlreadyStarted.selector);
        ballot.addVoters(voters);
    }

    function test_EligibleVotersCanVoteAndRevealAggregateResult() public {
        vm.warp(start);
        vm.prank(alice);
        ballot.vote(sbool(true));
        vm.prank(bob);
        ballot.vote(sbool(false));

        vm.warp(end);
        (uint256 forVotes, uint256 againstVotes) = ballot.results();
        assertEq(forVotes, 1);
        assertEq(againstVotes, 1);
        assertEq(uint256(ballot.outcome()), uint256(VeilVote.Outcome.Tied));
    }

    function test_AcceptedOutcome() public {
        vm.warp(start);
        vm.prank(alice);
        ballot.vote(sbool(true));

        vm.warp(end);
        assertEq(uint256(ballot.outcome()), uint256(VeilVote.Outcome.Accepted));
    }

    function test_RevertWhen_ResultRequestedEarly() public {
        vm.warp(start);
        vm.expectRevert(VeilVote.VotingStillOpen.selector);
        ballot.results();
    }

    function test_RevertWhen_IneligibleAddressVotes() public {
        vm.warp(start);
        vm.prank(outsider);
        vm.expectRevert(VeilVote.NotEligible.selector);
        ballot.vote(sbool(true));
    }

    function test_RevertWhen_VoterVotesTwice() public {
        vm.warp(start);
        vm.startPrank(alice);
        ballot.vote(sbool(true));
        vm.expectRevert(VeilVote.AlreadyVoted.selector);
        ballot.vote(sbool(false));
        vm.stopPrank();
    }

    function test_RevertWhen_VoteIsBeforeStart() public {
        vm.prank(alice);
        vm.expectRevert(VeilVote.VotingClosed.selector);
        ballot.vote(sbool(true));
    }

    function test_RevertWhen_VoteIsAtEnd() public {
        vm.warp(end);
        vm.prank(alice);
        vm.expectRevert(VeilVote.VotingClosed.selector);
        ballot.vote(sbool(true));
    }
}

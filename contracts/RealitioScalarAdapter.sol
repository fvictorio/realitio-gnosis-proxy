pragma solidity ^0.5.12;

import { IConditionalTokens, IRealitio } from "./Interfaces.sol";

contract RealitioScalarAdapter {
  IConditionalTokens public conditionalTokens;
  IRealitio public realitio;

  constructor(
    IConditionalTokens _conditionalTokens,
    IRealitio _realitio,
  ) public {
    conditionalTokens = _conditionalTokens;
    realitio = _realitio;
  }

  event QuestionIdAnnouncement(
    bytes32 indexed realitioQuestionId,
    bytes32 indexed conditionQuestionId
    uint256 low,
    uint256 high,
  );

  function announceConditionQuestionId(
    bytes32 questionId,
    uint256 low,
    uint256 high
  ) {
    emit QuestionIdAnnouncement(
      questionId,
      keccak256(abi.encode(
        questionId,
        low,
        high
      )),
      low,
      high
    );
  }

  function resolve(
    bytes32 questionId,
    uint256 templateId,
    string calldata question,
    uint256 low,
    uint256 high
  ) external {
    // check that the given templateId and question match the questionId
    bytes32 contentHash = keccak256(abi.encodePacked(
      templateId,
      realitio.getOpeningTS(questionId),
      question
    ));

    require(contentHash == realitio.getContentHash(questionId), "Content hash mismatch");
    require(templateId == 3, "Template ID must correspond with number type");
    require(low < high, "Range invalid");
    require(high != uint256(-1), "Invalid high point");

    uint256 size = high - low;

    uint256[] memory payouts = new uint256[](2);

    uint256 answer = uint256(realitio.resultFor(questionId));

    if (answer == uint256(-1)) {
      payouts[0] = 1;
      payouts[1] = 1;
    } else if (answer <= low) {
      payouts[0] = 1;
      payouts[1] = 0;
    } else if (answer >= high) {
      payouts[0] = 0;
      payouts[1] = 1;
    } else {
      payouts[0] = high - answer;
      payouts[1] = answer - low;
    }

    conditionalTokens.reportPayouts(
      keccak256(abi.encode(
        questionId,
        low,
        high
      )),
      payouts
    );
  }
}
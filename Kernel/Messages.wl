BeginPackage["ChristopherWolfram`OpenAILink`Messages`"];

Begin["`Private`"];

Needs["ChristopherWolfram`OpenAILink`"]
Needs["ChristopherWolfram`OpenAILink`Request`"]


OpenAIModels::openAIResponseFailureCode =
OpenAIRequest::openAIResponseFailureCode =
OpenAICompletion::openAIResponseFailureCode =
OpenAICreateImage::openAIResponseFailureCode =
OpenAIEmbedding::openAIResponseFailureCode = "Request to the OpenAI API failed with status code `1`.";

OpenAIModels::openAIResponseFailureMessage =
OpenAIRequest::openAIResponseFailureMessage =
OpenAICompletion::openAIResponseFailureMessage =
OpenAICreateImage::openAIResponseFailureMessage =
OpenAIEmbedding::openAIResponseFailureMessage = "Request to the OpenAI API failed with message: `1`.";

OpenAIModels::invalidOpenAIAPIKey =
OpenAIRequest::invalidOpenAIAPIKey =
OpenAICompletion::invalidOpenAIAPIKey =
OpenAICreateImage::invalidOpenAIAPIKey =
OpenAIEmbedding::invalidOpenAIAPIKey = "`1` is not a valid OpenAI API key. Consider setting the OpenAIKey option or the $OpenAIKey constant to a string containing a valid OpenAI API key.";

OpenAIModels::invOpenAIModelResponse = "The OpenAI API returned invalid model specification `1`.";

OpenAICompletion::invOpenAICompletionResponse = "The OpenAI API returned invalid completion specification `1`.";
OpenAICompletion::invPromptSpec = "Invalid prompt specification `1`. Expected a string or a pair of strings.";
OpenAICompletion::invUsageResponse = "Request to the OpenAI API returned an invalid report of its usage: `1`.";
OpenAICompletion::invProbResponse = "Request to the OpenAI API returned an invalid report of token probabilities `1`.";

OpenAICompletionObject::invOpenAICompletionObject = "Invalid OpenAICompletionObject with data `1`.";
OpenAICompletionObject::invProp = "`1` is not a known property of an OpenAICompletionObject.";

OpenAICreateImage::invOpenAICreateImageResponse = "TheOpenAI API returned invalid image specification `1`.";
OpenAICreateImage::invImageSize = "Invalid ImageSize specification `1`. Expected Small, Medium, Large, or a list of the target width and height.";

OpenAIEmbedding::invOpenAIEmbeddingResponse = "The OpenAI API returned invalid embedding specification `1`.";
OpenAIEmbedding::invProp = "`1` is not a known property for OpenAIEmbedding.";
OpenAIEmbedding::invUsageResponse = "Request to the OpenAI API returned an invalid report of its usage: `1`.";


End[];
EndPackage[];

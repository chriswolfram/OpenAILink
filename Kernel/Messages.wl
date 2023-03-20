BeginPackage["ChristopherWolfram`OpenAILink`Messages`"];

Begin["`Private`"];

Needs["ChristopherWolfram`OpenAILink`"]
Needs["ChristopherWolfram`OpenAILink`Request`"]


OpenAIFileDelete::openAIResponseFailureCode =
OpenAIFileInformation::openAIResponseFailureCode =
OpenAIModels::openAIResponseFailureCode =
OpenAIRequest::openAIResponseFailureCode =
OpenAITextCompletion::openAIResponseFailureCode =
OpenAIGenerateImage::openAIResponseFailureCode =
OpenAIEmbedding::openAIResponseFailureCode =
OpenAIFileUpload::openAIResponseFailureCode = "Request to the OpenAI API failed with status code `1`.";

OpenAIFileDelete::openAIResponseFailureCode =
OpenAIFileInformation::openAIResponseFailureMessage =
OpenAIModels::openAIResponseFailureMessage =
OpenAIRequest::openAIResponseFailureMessage =
OpenAITextCompletion::openAIResponseFailureMessage =
OpenAIGenerateImage::openAIResponseFailureMessage =
OpenAIEmbedding::openAIResponseFailureMessage =
OpenAIFileUpload::openAIResponseFailureMessage = "Request to the OpenAI API failed with message: `1`.";

OpenAIFileDelete::openAIResponseFailureCode =
OpenAIFileInformation::invalidOpenAIAPIKey =
OpenAIModels::invalidOpenAIAPIKey =
OpenAIRequest::invalidOpenAIAPIKey =
OpenAITextCompletion::invalidOpenAIAPIKey =
OpenAIGenerateImage::invalidOpenAIAPIKey =
OpenAIEmbedding::invalidOpenAIAPIKey =
OpenAIFileUpload::invalidOpenAIAPIKey = "`1` is not a valid OpenAI API key. Consider setting the OpenAIKey option or the $OpenAIKey constant to a string containing a valid OpenAI API key.";

OpenAIModels::invOpenAIModelResponse = "The OpenAI API returned invalid model specification `1`.";

OpenAITextCompletion::invOpenAITextCompletionResponse = "The OpenAI API returned invalid completion specification `1`.";
OpenAITextCompletion::invPromptSpec = "Invalid prompt specification `1`. Expected a string or a pair of strings.";
OpenAITextCompletion::invUsageResponse = "Request to the OpenAI API returned an invalid report of its usage: `1`.";
OpenAITextCompletion::invProbResponse = "Request to the OpenAI API returned an invalid report of token probabilities `1`.";

OpenAITextCompletionObject::invOpenAITextCompletionObject = "Invalid OpenAITextCompletionObject with data `1`.";
OpenAITextCompletionObject::invProp = "`1` is not a known property of an OpenAITextCompletionObject.";

OpenAIChatCompletion::invOpenAIChatCompletionResponse = "The OpenAI API returned invalid completion specification `1`.";
OpenAIChatCompletion::invPromptSpec = "Invalid prompt specification `1`. Expected an chat message or a list of chat messages.";

OpenAIChatCompletionObject::invOpenAIChatCompletionObject = "Invalid OpenAIChatCompletionObject with data `1`.";
OpenAIChatCompletionObject::invProp = "`1` is not a known property of an OpenAIChatCompletionObject.";

OpenAIChatMessageObject::invOpenAIChatMessageObject = "Invalid OpenAIChatMessageObject with data `1`.";
OpenAIChatMessageObject::invProp = "`1` is not a known property of an OpenAIChatMessageObject.";

OpenAIGenerateImage::invOpenAIGenerateImageResponse = "TheOpenAI API returned invalid image specification `1`.";
OpenAIGenerateImage::invImageSize = "Invalid ImageSize specification `1`. Expected Small, Medium, Large, or a list of the target width and height.";

OpenAIEmbedding::invOpenAIEmbeddingResponse = "The OpenAI API returned invalid embedding specification `1`.";
OpenAIEmbedding::invProp = "`1` is not a known property for OpenAIEmbedding.";
OpenAIEmbedding::invUsageResponse = "Request to the OpenAI API returned an invalid report of its usage: `1`.";

OpenAIFile::invOpenAIFile = "Invalid OpenAIFile object with data `1`.";


End[];
EndPackage[];

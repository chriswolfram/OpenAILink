BeginPackage["ChristopherWolfram`OpenAILink`Request`"];

OpenAIRequest
ConformUsage

Begin["`Private`"];

Needs["ChristopherWolfram`OpenAILink`"]
Needs["ChristopherWolfram`OpenAILink`Constants`"]



(***********************************************************************************)
(********************************* OpenAIRequest ***********************************)
(***********************************************************************************)

(*
	OpenAIRequest[path, body, opts, head]
		makes a request to the OpenAI API at the specified path and with the specified body.

		path: a list of strings in the format expected by URLRead.

		body: an expression which is automatically converted to JSON. If the body is None, no body will be specified.

		opts: a list containing the options passed to the higher-level request function.

		head: the head of the higher-level request function for use in option resolution and messages.
*)

Options[OpenAIRequest] = {
	OpenAIKey  :> $OpenAIKey,
	OpenAIUser :> $OpenAIUser
};

OpenAIRequest[path_, body_:None, opts_List:{}, head_:OpenAIRequest] :=
	Enclose[Module[{apiKey, user, bodyRule, resp},

		apiKey = OptionValue[head, opts, OpenAIKey];
		user = OptionValue[head, opts, OpenAIUser];

		ConfirmBy[apiKey, StringQ, Message[head::invalidOpenAIAPIKey, apiKey]];

		bodyRule =
			If[body === None,
				Nothing,
				"Body" -> Confirm@ExportString[If[user =!= None, Append[body, "user" -> user], body], "JSON"]
			];

		resp = URLRead[
			<|
				"Scheme" -> "https",
				"Domain" -> "api.openai.com",
				"Method" -> If[body === None, "GET", "POST"],
				"ContentType" -> "application/json",
				"Path" -> path,
				bodyRule,
				"Headers" -> {
					"Authorization" -> "Bearer " <> apiKey
				}
			|>
		];

		conformResponse[head, resp]

	], $Failed&]


(*
	conformResponse[head, resp]
		takes an HTTPResponse and returns the contained JSON data. Returns a Failure if the request failed.

		head is used for messages.
*)

conformResponse[head_, resp_] :=
	Catch@Module[{statusCode, body},

		statusCode = resp["StatusCode"];
		body = ImportString[ToString[resp["Body"],CharacterEncoding->"UTF8"], "RawJSON"];

		If[FailureQ[body],
			Throw@responseFailureCode[head, resp, statusCode]
		];

		Which[

			KeyExistsQ[body,"error"],
				If[KeyExistsQ[body["error"],"message"],
					Throw@responseFailureMessage[head, resp, body["error"]["message"]],
					Throw@responseFailureCode[head, resp, statusCode]
				],

			statusCode =!= 200,
				Throw@responseFailureCode[head, resp, statusCode],

			True,
				body

		]
		
	]


responseFailureCode[head_, resp_, code_] :=
	(
		Message[head::openAIResponseFailureCode, code];
		Failure["OpenAIResponseFailure", <|
			"MessageTemplate" :> head::openAIResponseFailureCode,
			"MessageParameters" -> {code},
			"HTTPResponse" -> resp
		|>]
	)


responseFailureMessage[head_, resp_, message_] :=
	(
		Message[head::openAIResponseFailureMessage, message];
		Failure["OpenAIResponseFailure", <|
			"MessageTemplate" :> head::openAIResponseFailureMessage,
			"MessageParameters" -> {message},
			"HTTPResponse" -> resp
		|>]
	)



End[];
EndPackage[];

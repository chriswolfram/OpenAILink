BeginPackage["ChristopherWolfram`OpenAILink`Models`"];

Begin["`Private`"];

Needs["ChristopherWolfram`OpenAILink`"]
Needs["ChristopherWolfram`OpenAILink`Constants`"]
Needs["ChristopherWolfram`OpenAILink`Request`"]



(***********************************************************************************)
(********************************** OpenAIModels ***********************************)
(***********************************************************************************)

(*
	OpenAIModels[]
		gives a list of supported models.
*)

Options[OpenAIModels] = {
	OpenAIKey  :> $OpenAIKey,
	OpenAIUser :> $OpenAIUser
};

OpenAIModels[opts:OptionsPattern[]] :=
	conformModels@OpenAIRequest[
		{"v1", "models"},
		None,
		{opts},
		OpenAIModels
	]


conformModels[data_] :=
	Enclose[
		Module[{list},
			ConfirmAssert[data["object"] === "list"];
			list = Confirm[data["data"]];
			Lookup[#, "id", Message[OpenAIModels::invOpenAIModelResponse, #];Nothing] &/@ list
		],
		(
			Message[OpenAIModels::invOpenAIModelResponse, data];
			Failure["InvalidOpenAIModelResponse", <|
				"MessageTemplate" :> OpenAIModels::invOpenAIModelResponse,
				"MessageParameters" -> {data},
				"Response" -> data,
				"ConfirmationFailure" -> #
			|>]
		)&
	]

conformModels[fail_?FailureQ] :=
	fail



End[];
EndPackage[];

BeginPackage["ChristopherWolfram`OpenAILink`Completion`"];

Begin["`Private`"];

Needs["ChristopherWolfram`OpenAILink`"]
Needs["ChristopherWolfram`OpenAILink`Constants`"]
Needs["ChristopherWolfram`OpenAILink`Request`"]



(***********************************************************************************)
(******************************** OpenAICompletion *********************************)
(***********************************************************************************)

(*
	OpenAICompletion[prompt]
		completes the string starting with the prompt.

	OpenAICompletion[{prompt, suffix}]
		generates a completion that can be inserted between prompt and suffix.

	OpenAICompletion[promptSpec, propSpec]
		returns the property of list of properties specified by propSpec.

	OpenAICompletion[promptSpec, All]
		returns a OpenAICompletionObject containing all results of the completion.

	OpenAICompletion[promptSpec, propSpec, n]
		generates n completions.
*)

Options[OpenAICompletion] = {
	OpenAIKey            :> $OpenAIKey,
	OpenAIUser           :> $OpenAIUser,
	OpenAIModel          -> "text-davinci-003",
	OpenAITemperature    -> Automatic,
	OpenAITopProbability -> Automatic,
	OpenAITokenLimit     -> Automatic,
	OpenAIStopTokens     -> Automatic
};

OpenAICompletion[promptSpec_, propSpec: _String | {___String} | All, n_Integer, opts:OptionsPattern[]] :=
	Enclose[
		ConfirmMatch[promptSpec, _String | {_String, _String},
			Message[OpenAICompletion::invPromptSpec, promptSpec];
			Failure["InvalidPromptSpecification", <|
				"MessageTemplate" :> OpenAICompletion::invPromptSpec,
				"MessageParameters" -> {promptSpec},
				"PromptSpecification" -> promptSpec
			|>]
		];
		conformCompletion[
			OpenAIRequest[
				{"v1", "completions"},
				Select[
					<|
						"model" -> OptionValue[OpenAIModel],
						"prompt" -> promptSpecPrompt[promptSpec],
						"suffix" -> promptSpecSuffix[promptSpec],
						"n" -> n,
						"temperature" -> OptionValue[OpenAITemperature],
						"top_p" -> OptionValue[OpenAITopProbability],
						"max_tokens" -> OptionValue[OpenAITokenLimit],
						"stop" -> OptionValue[OpenAIStopTokens]
					|>,
					# =!= Automatic&
				],
				{opts},
				OpenAICompletion
			],
			propSpec,
			{promptSpecPrompt[promptSpec], promptSpecSuffix[promptSpec]}
		],
		"InheritedFailure"
	]

OpenAICompletion[promptSpec_, propSpec: _String | {___String} | All, opts:OptionsPattern[]] :=
	Replace[OpenAICompletion[promptSpec, propSpec, 1, opts], {res_} :> res]

OpenAICompletion[promptSpec_, opts:OptionsPattern[]] :=
	OpenAICompletion[promptSpec, "Completion", opts]


promptSpecPrompt[prompt_] := prompt
promptSpecPrompt[{prompt_, suffix_}] := prompt

promptSpecSuffix[prompt_] := Automatic
promptSpecSuffix[{prompt_, suffix_}] := suffix



conformCompletion[data_, propSpec_, promptSuffix_] :=
	Enclose[
		Module[{model, usage, choices},
			model = Confirm[data["model"]];
			usage = conformUsage[Confirm[data["usage"]]];
			choices = ConfirmMatch[data["choices"], _List];

			conformCompletionChoice[#, promptSuffix, model, usage, propSpec] &/@ choices
		],
		completionResponseError[data, #]&
	]


conformCompletionChoice[choice_, {prompt_, suffix_}, model_, usage_, All] :=
	Enclose[
		OpenAICompletionObject[<|
			"Prompt" -> prompt,
			"Suffix" -> suffix,
			"Completion" -> Confirm@choice["text"],
			"Model" -> model,
			"FinishReason" -> Replace[Confirm@choice["finish_reason"], {"length" -> "Length", "stop" -> "Stop"}],
			"ResponseUsage" -> usage
		|>],
		completionResponseError[data, #]&
	]

conformCompletionChoice[choice_, promptSuffix_, model_, usage_, props_List] :=
	Enclose[
		With[{completion = Confirm@conformCompletionChoice[choice, promptSuffix, model, usage, All]},
			completion[#] &/@ props
		],
		"InheritedFailure"
	]

conformCompletionChoice[choice_, promptSuffix_, model_, usage_, prop_] :=
	First@conformCompletionChoice[choice, promptSuffix, model, usage, {prop}]


conformUsage[KeyValuePattern[{
		"prompt_tokens" -> pTokens_Integer,
		"completion_tokens" -> cTokens_Integer,
		"total_tokens" -> tTokens_Integer
	}]] :=
	<|
		"PromptTokens" -> pTokens,
		"CompletionTokens" -> cTokens,
		"TotalTokens" -> tTokens
	|>

conformUsage[usage_] :=
	Failure["InvalidUsageResponse", <|
		"MessageTemplate" :> OpenAICompletion::invUsageResponse,
		"MessageParameters" -> usage
	|>]



completionResponseError[data_, confirmationFailure_] :=
	(
		Message[OpenAICompletion::invOpenAICompletionResponse, data];
		Failure["InvalidOpenAICompletionResponse", <|
			"MessageTemplate" :> OpenAICompletion::invOpenAICompletionResponse,
			"MessageParameters" -> {data},
			"Response" -> data,
			"ConfirmationFailure" -> confirmationFailure
		|>]
	)



(***********************************************************************************)
(***************************** OpenAICompletionObject ******************************)
(***********************************************************************************)


(***** Verifier *****)

HoldPattern[OpenAICompletionObject][data:Except[KeyValuePattern[{
		"Completion" -> _String,
		"Prompt" -> _String,
		"Suffix" -> _String | Automatic,
		"Model" -> _,
		"FinishReason" -> _,
		"ResponseUsage" -> _
	}]]] :=
	(
		Message[OpenAICompletionObject::invOpenAICompletionObject, data];
		Failure["InvalidOpenAICompletionObject", <|
			"MessageTemplate" :> OpenAICompletionObject::invOpenAICompletionObject,
			"MessageParameters" -> {data},
			"Data" -> data
		|>]
	)


(***** Accessors *****)

HoldPattern[OpenAICompletionObject][data_]["Data"] := data
completion_OpenAICompletionObject[All] := completion[#] &/@ completion["Properties"]

completion_OpenAICompletionObject["Completion"] := completion["Data"]["Completion"]
completion_OpenAICompletionObject["Prompt"] := completion["Data"]["Prompt"]
completion_OpenAICompletionObject["Suffix"] := completion["Data"]["Suffix"]
completion_OpenAICompletionObject["Model"] := completion["Data"]["Model"]
completion_OpenAICompletionObject["FinishReason"] := completion["Data"]["FinishReason"]
completion_OpenAICompletionObject["ResponseUsage"] := completion["Data"]["ResponseUsage"]

completion_OpenAICompletionObject["CompletedPrompt"] :=
	completion["Prompt"] <> completion["Completion"] <> Replace[completion["Suffix"], Automatic -> ""]


completion_OpenAICompletionObject["Properties"] :=
	Sort@{
		"CompletedPrompt",
		"Completion",
		"Prompt",
		"Suffix",
		"Model",
		"FinishReason",
		"ResponseUsage"
	}

completion_OpenAICompletionObject[prop_] :=
	(
		Message[OpenAICompletionObject::invProp, prop];
		Failure["InvalidProperty", <|
			"MessageTemplate" :> OpenAICompletionObject::invProp,
			"MessageParameters" -> {prop},
			"Property" -> prop,
			"Completion" -> completion
		|>]
	)


(***** Summary Box *****)

OpenAICompletionObject /: MakeBoxes[completion_OpenAICompletionObject, form:StandardForm]:=
	BoxForm`ArrangeSummaryBox[
		OpenAICompletionObject,
		completion,
		None,
		(*the next argument is the always visisble properties*)
		{
			{"prompt: ", completion["Prompt"]},
			{"completion: ", completion["Completion"]},
			If[completion["Suffix"] =!= Automatic,
				{"suffix: ", completion["Suffix"]},
				Nothing
			],
			{"finish reason: ", completion["FinishReason"]}
		},
		{
			{"model: ", completion["Model"]},
			{"response usage: ", completion["ResponseUsage"]}
		},
		form
	];



End[];
EndPackage[];

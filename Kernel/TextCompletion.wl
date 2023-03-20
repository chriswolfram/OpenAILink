BeginPackage["ChristopherWolfram`OpenAILink`TextCompletion`"];

Begin["`Private`"];

Needs["ChristopherWolfram`OpenAILink`"]
Needs["ChristopherWolfram`OpenAILink`Constants`"]
Needs["ChristopherWolfram`OpenAILink`Request`"]



(***********************************************************************************)
(****************************** OpenAITextCompletion *******************************)
(***********************************************************************************)

(*
	OpenAITextCompletion[prompt]
		completes the string starting with the prompt.

	OpenAITextCompletion[{prompt, suffix}]
		generates a completion that can be inserted between prompt and suffix.

	OpenAITextCompletion[promptSpec, propSpec]
		returns the property or list of properties specified by propSpec.

	OpenAITextCompletion[promptSpec, All]
		returns a OpenAITextCompletionObject containing all results of the completion.

	OpenAITextCompletion[promptSpec, propSpec, n]
		generates n completions.
*)

Options[OpenAITextCompletion] = {
	OpenAIKey            :> $OpenAIKey,
	OpenAIUser           :> $OpenAIUser,
	OpenAIModel          -> Automatic,
	OpenAITemperature    -> Automatic,
	OpenAITopProbability -> Automatic,
	OpenAITokenLimit     -> Automatic,
	OpenAIStopTokens     -> Automatic
};

OpenAITextCompletion[args___] :=
	Enclose[
		iOpenAITextCompletion@Confirm@ArgumentsOptions[OpenAITextCompletion[args], {1,3}],
		"InheritedFailiure"
	]


(* Completion *)
iOpenAITextCompletion[{{{prompt_String, suffix:_String|Automatic}, propSpec_, n_}, opts_}] :=
	Module[{rawResponse},
		rawResponse =
			OpenAIRequest[
				{"v1", "completions"},
				Select[
					<|
						"model" -> Replace[OptionValue[OpenAITextCompletion,opts,OpenAIModel], Automatic -> "text-davinci-003"],
						"prompt" -> prompt,
						"suffix" -> suffix,
						"n" -> n,
						"temperature" -> OptionValue[OpenAITextCompletion,opts,OpenAITemperature],
						"top_p" -> OptionValue[OpenAITextCompletion,opts,OpenAITopProbability],
						"max_tokens" -> OptionValue[OpenAITextCompletion,opts,OpenAITokenLimit],
						"stop" -> OptionValue[OpenAITextCompletion,opts,OpenAIStopTokens],
						"logprobs" -> 5
					|>,
					# =!= Automatic&
				],
				{opts},
				OpenAITextCompletion
			];
		conformCompletion[rawResponse, propSpec, {prompt, suffix}]
	]

iOpenAITextCompletion[{{prompt_String, propSpec_, n_}, opts_}] :=
	iOpenAITextCompletion[{{{prompt, Automatic}, propSpec, n}, opts}]

iOpenAITextCompletion[{{promptSpec_, propSpec_, n_}, opts_}] :=
	(
		Message[OpenAITextCompletion::invPromptSpec, promptSpec];
		Failure["InvalidPromptSpecification", <|
			"MessageTemplate" :> OpenAITextCompletion::invPromptSpec,
			"MessageParameters" -> {promptSpec},
			"PromptSpecification" -> promptSpec
		|>]
)

iOpenAITextCompletion[{{promptSpec_, propSpec_}, opts_}] :=
	Replace[iOpenAITextCompletion[{{promptSpec, propSpec, 1}, opts}], {res_} :> res]

iOpenAITextCompletion[{{promptSpec_}, opts_}] :=
	iOpenAITextCompletion[{{promptSpec, "Completion"}, opts}]


conformCompletion[KeyValuePattern[{
		"model" -> model_,
		"usage" -> rawUsage_,
		"choices" -> choices_List
	}], propSpec_, promptSuffix_] :=
	With[{usage = conformUsage[rawUsage]},
		getChoiceProperty[conformCompletionChoice[#, promptSuffix, model, usage], propSpec] &/@ choices
	]

conformCompletion[fail_?FailureQ, propSpec_, promptSuffix_] :=
	fail

conformCompletion[data_, propSpec_, promptSuffix_] :=
	completionResponseError[data]


getChoiceProperty[choice_OpenAITextCompletionObject, All] :=
	choice

getChoiceProperty[choice_OpenAITextCompletionObject, props_List] :=
	choice/@props

getChoiceProperty[choice_OpenAITextCompletionObject, prop_] :=
	choice[prop]

getChoiceProperty[choice_, propSpec_] :=
	choice


conformCompletionChoice[choice: KeyValuePattern[{
		"text" -> text_,
		"finish_reason" -> finishReason_
	}], {prompt_, suffix_}, model_, usage_] :=
	OpenAITextCompletionObject[<|
		"Prompt" -> prompt,
		"Suffix" -> suffix,
		"Completion" -> text,
		"Model" -> model,
		"FinishReason" -> Replace[finishReason, {"length" -> "Length", "stop" -> "Stop"}],
		"ResponseUsage" -> usage,
		"LogProbabilities" -> conformLogProbabilities[choice]
	|>]

conformCompletionChoice[data_, {prompt_, suffix_}, model_, usage_] :=
	completionResponseError[data]


conformLogProbabilities[KeyValuePattern[{"logprobs" -> KeyValuePattern[{"top_logprobs" -> probs:{___?AssociationQ}}]}]] :=
	KeyMap[Replace["<|endoftext|>" -> EndOfString]] /@ probs

conformLogProbabilities[choice_] :=
	Failure["InvalidProbabilitiesResponse", <|
		"MessageTemplate" :> OpenAITextCompletion::invProbResponse,
		"MessageParameters" -> {choice["logprobs"]},
		"Response" -> choice
	|>]


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
		"MessageTemplate" :> OpenAITextCompletion::invUsageResponse,
		"MessageParameters" -> {usage}
	|>]


completionResponseError[data_] :=
	(
		Message[OpenAITextCompletion::invOpenAITextCompletionResponse, data];
		Failure["InvalidOpenAITextCompletionResponse", <|
			"MessageTemplate" :> OpenAITextCompletion::invOpenAITextCompletionResponse,
			"MessageParameters" -> {data},
			"Response" -> data
		|>]
	)


(***********************************************************************************)
(*************************** OpenAITextCompletionObject ****************************)
(***********************************************************************************)


(***** Verifier *****)

HoldPattern[OpenAITextCompletionObject][data:Except[KeyValuePattern[{
		"Completion" -> _String,
		"Prompt" -> _String,
		"Suffix" -> _String | Automatic,
		"Model" -> _,
		"FinishReason" -> _,
		"ResponseUsage" -> _,
		"LogProbabilities" -> {___?AssociationQ}
	}]]] :=
	(
		Message[OpenAITextCompletionObject::invOpenAITextCompletionObject, data];
		Failure["InvalidOpenAITextCompletionObject", <|
			"MessageTemplate" :> OpenAITextCompletionObject::invOpenAITextCompletionObject,
			"MessageParameters" -> {data},
			"Data" -> data
		|>]
	)


(***** Accessors *****)

HoldPattern[OpenAITextCompletionObject][data_]["Data"] := data
completion_OpenAITextCompletionObject[All] := AssociationMap[completion[#]&, completion["Properties"]]

completion_OpenAITextCompletionObject["Completion"] := completion["Data"]["Completion"]
completion_OpenAITextCompletionObject["Prompt"] := completion["Data"]["Prompt"]
completion_OpenAITextCompletionObject["Suffix"] := completion["Data"]["Suffix"]
completion_OpenAITextCompletionObject["Model"] := completion["Data"]["Model"]
completion_OpenAITextCompletionObject["FinishReason"] := completion["Data"]["FinishReason"]
completion_OpenAITextCompletionObject["ResponseUsage"] := completion["Data"]["ResponseUsage"]
completion_OpenAITextCompletionObject["LogProbabilities"] := completion["Data"]["LogProbabilities"]

completion_OpenAITextCompletionObject["CompletedPrompt"] :=
	completion["Prompt"] <> completion["Completion"] <> Replace[completion["Suffix"], Automatic -> ""]

completion_OpenAITextCompletionObject["Probabilities"] := Exp@completion["LogProbabilities"]


completion_OpenAITextCompletionObject["Properties"] :=
	Sort@{
		"CompletedPrompt",
		"Completion",
		"Prompt",
		"Suffix",
		"Model",
		"FinishReason",
		"ResponseUsage",
		"LogProbabilities",
		"Probabilities"
	}

completion_OpenAITextCompletionObject[prop_] :=
	(
		Message[OpenAITextCompletionObject::invProp, prop];
		Failure["InvalidProperty", <|
			"MessageTemplate" :> OpenAITextCompletionObject::invProp,
			"MessageParameters" -> {prop},
			"Property" -> prop,
			"Completion" -> completion
		|>]
	)


(***** Summary Box *****)

OpenAITextCompletionObject /: MakeBoxes[completion_OpenAITextCompletionObject, form:StandardForm]:=
	BoxForm`ArrangeSummaryBox[
		OpenAITextCompletionObject,
		completion,
		None,
		(*the next argument is the always visisble properties*)
		{
			BoxForm`SummaryItem@{"prompt: ", completion["Prompt"]},
			BoxForm`SummaryItem@{"completion: ", completion["Completion"]},
			If[completion["Suffix"] =!= Automatic,
				BoxForm`SummaryItem@{"suffix: ", completion["Suffix"]},
				Nothing
			],
			BoxForm`SummaryItem@{"finish reason: ", completion["FinishReason"]}
		},
		{
			BoxForm`SummaryItem@{"model: ", completion["Model"]},
			BoxForm`SummaryItem@{"response usage: ", completion["ResponseUsage"]}
		},
		form
	];



End[];
EndPackage[];

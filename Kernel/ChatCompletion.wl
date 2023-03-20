BeginPackage["ChristopherWolfram`OpenAILink`ChatCompletion`"];

Begin["`Private`"];

Needs["ChristopherWolfram`OpenAILink`"]
Needs["ChristopherWolfram`OpenAILink`Constants`"]
Needs["ChristopherWolfram`OpenAILink`Request`"]



(***********************************************************************************)
(****************************** OpenAITextCompletion *******************************)
(***********************************************************************************)

(*
	OpenAICompletion[prompt]
		completes the string starting with the prompt.

	OpenAICompletion[{prompt, suffix}]
		generates a completion that can be inserted between prompt and suffix.

	OpenAICompletion[chat]
		completes the chat conversation.

	OpenAICompletion[promptSpec, propSpec]
		returns the property or list of properties specified by propSpec.

	OpenAICompletion[promptSpec, All]
		returns a OpenAICompletionObject containing all results of the completion.

	OpenAICompletion[promptSpec, propSpec, n]
		generates n completions.
*)

Options[OpenAICompletion] = {
	OpenAIKey            :> $OpenAIKey,
	OpenAIUser           :> $OpenAIUser,
	OpenAIModel          -> Automatic,
	OpenAITemperature    -> Automatic,
	OpenAITopProbability -> Automatic,
	OpenAITokenLimit     -> Automatic,
	OpenAIStopTokens     -> Automatic
};

OpenAICompletion[args___] :=
	Enclose[
		iOpenAICompletion@Confirm@ArgumentsOptions[OpenAICompletion[args], {1,3}],
		"InheritedFailiure"
	]


(* Completion *)
iOpenAICompletion[{{{prompt_String, suffix:_String|Automatic}, propSpec_, n_}, opts_}] :=
	Module[{rawResponse},
		rawResponse =
			OpenAIRequest[
				{"v1", "completions"},
				Select[
					<|
						"model" -> Replace[OptionValue[OpenAICompletion,opts,OpenAIModel], Automatic -> "text-davinci-003"],
						"prompt" -> prompt,
						"suffix" -> suffix,
						"n" -> n,
						"temperature" -> OptionValue[OpenAICompletion,opts,OpenAITemperature],
						"top_p" -> OptionValue[OpenAICompletion,opts,OpenAITopProbability],
						"max_tokens" -> OptionValue[OpenAICompletion,opts,OpenAITokenLimit],
						"stop" -> OptionValue[OpenAICompletion,opts,OpenAIStopTokens],
						"logprobs" -> 5
					|>,
					# =!= Automatic&
				],
				{opts},
				OpenAICompletion
			];
	conformCompletion[rawResponse, propSpec, {prompt, suffix}]
	]

iOpenAICompletion[{{prompt_String, propSpec_, n_}, opts_}] :=
	iOpenAICompletion[{{{prompt, Automatic}, propSpec, n}, opts}]


(* Chat *)
iOpenAICompletion[{{promptMsgs:{__OpenAIChatMessageObject}, propSpec_, n_}, opts_}] :=
	Module[{rawResponse},
		rawResponse =
			OpenAIRequest[
				{"v1", "chat", "completions"},
				Select[
					<|
						"model" -> Replace[OptionValue[OpenAICompletion,opts,OpenAIModel], Automatic -> "gpt-3.5-turbo"],
						"messages" -> chatMessageJSON/@promptMsgs,
						"n" -> n,
						"temperature" -> OptionValue[OpenAICompletion,opts,OpenAITemperature],
						"top_p" -> OptionValue[OpenAICompletion,opts,OpenAITopProbability],
						"max_tokens" -> OptionValue[OpenAICompletion,opts,OpenAITokenLimit],
						"stop" -> OptionValue[OpenAICompletion,opts,OpenAIStopTokens]
					|>,
					# =!= Automatic&
				],
				{opts},
				OpenAICompletion
			];
		conformChat[rawResponse, propSpec, promptMsgs]
	]

iOpenAICompletion[{{promptMsg_OpenAIChatMessageObject, propSpec_, n_}, opts_}] :=
	iOpenAICompletion[{{{promptMsg}, propSpec, n}, opts}]


iOpenAICompletion[{{promptSpec_, propSpec_, n_}, opts_}] :=
	(
		Message[OpenAICompletion::invPromptSpec, promptSpec];
		Failure["InvalidPromptSpecification", <|
			"MessageTemplate" :> OpenAICompletion::invPromptSpec,
			"MessageParameters" -> {promptSpec},
			"PromptSpecification" -> promptSpec
		|>]
)


iOpenAICompletion[{{promptSpec_, propSpec_}, opts_}] :=
	Replace[iOpenAICompletion[{{promptSpec, propSpec, 1}, opts}], {res_} :> res]

iOpenAICompletion[{{promptSpec_}, opts_}] :=
	iOpenAICompletion[{{promptSpec, "Completion"}, opts}]


(* Conform completion response *)

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

conformCompletion[fail_?FailureQ, propSpec_, promptSuffix_] :=
	fail


conformCompletionChoice[choice_, {prompt_, suffix_}, model_, usage_, All] :=
	Enclose[
		OpenAICompletionObject[<|
			"Prompt" -> prompt,
			"Suffix" -> suffix,
			"Completion" -> Confirm@choice["text"],
			"Model" -> model,
			"FinishReason" -> Replace[Confirm@choice["finish_reason"], {"length" -> "Length", "stop" -> "Stop"}],
			"ResponseUsage" -> usage,
			"LogProbabilities" -> Confirm@conformLogProbabilities[choice]
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


conformLogProbabilities[KeyValuePattern[{"logprobs" -> KeyValuePattern[{"top_logprobs" -> probs:{___?AssociationQ}}]}]] :=
	KeyMap[Replace["<|endoftext|>" -> EndOfString]] /@ probs

conformLogProbabilities[choice_] :=
	Failure["InvalidProbabilitiesResponse", <|
		"MessageTemplate" :> OpenAICompletion::invProbResponse,
		"MessageParameters" -> {choice["logprobs"]},
		"Response" -> choice
	|>]



(* Conform chat response *)

conformChat[data_, propSpec_, promptMsgs_] :=
	Enclose[
		Module[{model, usage, choices},
			model = Confirm[data["model"]];
			usage = conformUsage[Confirm[data["usage"]]];
			choices = ConfirmMatch[data["choices"], _List];

			conformChatChoice[#, promptMsgs, model, usage, propSpec] &/@ choices
		],
		completionResponseError[data, #]&
	]

conformChat[fail_?FailureQ, propSpec_, promptMsgs_] :=
	fail


conformChatChoice[choice_, promptMsgs_, model_, usage_, All] :=
	Enclose[
		OpenAIChatObject[<|
			"CompletionMessage" -> Confirm@jsonToMessageObject@choice["message"],
			"PromptMessages" -> promptMsgs,
			"Model" -> model,
			"FinishReason" -> Replace[Confirm@choice["finish_reason"], {"length" -> "Length", "stop" -> "Stop"}],
			"ResponseUsage" -> usage
		|>],
		completionResponseError[data, #]&
	]

conformChatChoice[choice_, promptMsgs_, model_, usage_, props_List] :=
	Enclose[
		With[{chat = Confirm@conformChatChoice[choice, promptMsgs, model, usage, All]},
			chat[#] &/@ props
		],
		"InheritedFailure"
	]

conformChatChoice[choice_, promptMsgs_, model_, usage_, prop_] :=
	First@conformChatChoice[choice, promptMsgs, model, usage, {prop}]


jsonToMessageObject[json_] :=
	Enclose[
		OpenAIChatMessageObject[<|
			"Role" -> ConfirmMatch[json["role"], _String],
			"Text" -> ConfirmMatch[json["content"], _String]
		|>]
	]



(* Utilities *)

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
		"MessageParameters" -> {usage}
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
		"ResponseUsage" -> _,
		"LogProbabilities" -> {___?AssociationQ}
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
completion_OpenAICompletionObject[All] := AssociationMap[completion[#]&, completion["Properties"]]

completion_OpenAICompletionObject["Completion"] := completion["Data"]["Completion"]
completion_OpenAICompletionObject["Prompt"] := completion["Data"]["Prompt"]
completion_OpenAICompletionObject["Suffix"] := completion["Data"]["Suffix"]
completion_OpenAICompletionObject["Model"] := completion["Data"]["Model"]
completion_OpenAICompletionObject["FinishReason"] := completion["Data"]["FinishReason"]
completion_OpenAICompletionObject["ResponseUsage"] := completion["Data"]["ResponseUsage"]
completion_OpenAICompletionObject["LogProbabilities"] := completion["Data"]["LogProbabilities"]

completion_OpenAICompletionObject["CompletedPrompt"] :=
	completion["Prompt"] <> completion["Completion"] <> Replace[completion["Suffix"], Automatic -> ""]

completion_OpenAICompletionObject["Probabilities"] := Exp@completion["LogProbabilities"]


completion_OpenAICompletionObject["Properties"] :=
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



(***********************************************************************************)
(******************************** OpenAIChatObject *********************************)
(***********************************************************************************)


(***** Verifier *****)

HoldPattern[OpenAIChatObject][data:Except[KeyValuePattern[{
		"CompletionMessage" -> _OpenAIChatMessageObject,
		"PromptMessages" -> {___OpenAIChatMessageObject},
		"Model" -> _,
		"FinishReason" -> _,
		"ResponseUsage" -> _
	}]]] :=
	(
		Message[OpenAIChatObject::invOpenAIChatObject, data];
		Failure["InvalidOpenAICompletionObject", <|
			"MessageTemplate" :> OpenAIChatObject::invOpenAIChatObject,
			"MessageParameters" -> {data},
			"Data" -> data
		|>]
	)


(***** Accessors *****)

HoldPattern[OpenAIChatObject][data_]["Data"] := data
chat_OpenAIChatObject[All] := AssociationMap[chat[#]&, chat["Properties"]]

chat_OpenAIChatObject["CompletionMessage"] := chat["Data"]["CompletionMessage"]
chat_OpenAIChatObject["PromptMessages"] := chat["Data"]["PromptMessages"]
chat_OpenAIChatObject["Model"] := chat["Data"]["Model"]
chat_OpenAIChatObject["FinishReason"] := chat["Data"]["FinishReason"]
chat_OpenAIChatObject["ResponseUsage"] := chat["Data"]["ResponseUsage"]

chat_OpenAIChatObject["Completion"] := chat["CompletionMessage"]
chat_OpenAIChatObject["Messages"] := Append[chat["PromptMessages"], chat["CompletionMessage"]]

chat_OpenAIChatObject["Properties"] :=
	Sort@{
		"CompletionMessage",
		"PromptMessages",
		"Messages",
		"Model",
		"FinishReason",
		"ResponseUsage"
	}

chat_OpenAIChatObject[prop_] :=
	(
		Message[OpenAIChatObject::invProp, prop];
		Failure["InvalidProperty", <|
			"MessageTemplate" :> OpenAIChatObject::invProp,
			"MessageParameters" -> {prop},
			"Property" -> prop,
			"Completion" -> chat
		|>]
	)


(***** Summary Box *****)

OpenAIChatObject /: MakeBoxes[chat_OpenAIChatObject, form:StandardForm]:=
	BoxForm`ArrangeSummaryBox[
		OpenAIChatObject,
		chat,
		None,
		(*the next argument is the always visisble properties*)
		{
			BoxForm`SummaryItem@{"prompt: ", chat["PromptMessages"]},
			BoxForm`SummaryItem@{"completion: ", chat["CompletionMessage"]}
		},
		{
			BoxForm`SummaryItem@{"model: ", completion["Model"]},
			BoxForm`SummaryItem@{"finish reason: ", completion["FinishReason"]},
			BoxForm`SummaryItem@{"response usage: ", completion["ResponseUsage"]}
		},
		form
	];


(***********************************************************************************)
(***************************** OpenAIChatMessageObject *****************************)
(***********************************************************************************)


(***** Verifier *****)

HoldPattern[OpenAIChatMessageObject][role_String, text_String] :=
	OpenAIChatMessageObject[<|"Role" -> role, "Text" -> text|>]

HoldPattern[OpenAIChatMessageObject][data:Except[KeyValuePattern[{
		"Role" -> _String,
		"Text" -> _String
	}]]] :=
	(
		Message[OpenAIChatMessageObject::invOpenAIChatMessageObject, data];
		Failure["InvalidOpenAIChatMessageObject", <|
			"MessageTemplate" :> OpenAIChatMessageObject::invOpenAIChatMessageObject,
			"MessageParameters" -> {data},
			"Data" -> data
		|>]
	)


(***** Accessors *****)

HoldPattern[OpenAIChatMessageObject][data_]["Data"] := data
msg_OpenAIChatMessageObject[All] := AssociationMap[msg[#]&, msg["Properties"]]

msg_OpenAIChatMessageObject["Role"] := msg["Data"]["Role"]
msg_OpenAIChatMessageObject["Text"] := msg["Data"]["Text"]

msg_OpenAIChatMessageObject["Properties"] :=
	Sort@{
		"Role",
		"Text"
	}

msg_OpenAIChatMessageObject[prop_] :=
	(
		Message[OpenAIChatMessageObject::invProp, prop];
		Failure["InvalidProperty", <|
			"MessageTemplate" :> OpenAIChatMessageObject::invProp,
			"MessageParameters" -> {prop},
			"Property" -> prop,
			"Completion" -> msg
		|>]
	)


chatMessageJSON[msg_OpenAIChatMessageObject] :=
	<|"role" -> msg["Role"], "content" -> msg["Text"]|>


(***** Summary Box *****)

OpenAIChatMessageObject /: MakeBoxes[msg_OpenAIChatMessageObject, form:StandardForm]:=
	BoxForm`ArrangeSummaryBox[
		OpenAIChatMessageObject,
		msg,
		None,
		(*the next argument is the always visisble properties*)
		{
			BoxForm`SummaryItem@{"role: ", msg["Role"]},
			BoxForm`SummaryItem@{"text: ", msg["Text"]}
		},
		{},
		form
	];



End[];
EndPackage[];

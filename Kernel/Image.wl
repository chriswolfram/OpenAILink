BeginPackage["ChristopherWolfram`OpenAILink`Image`"];

Begin["`Private`"];

Needs["ChristopherWolfram`OpenAILink`"]
Needs["ChristopherWolfram`OpenAILink`Constants`"]
Needs["ChristopherWolfram`OpenAILink`Request`"]



(***********************************************************************************)
(******************************** OpenAICreateImage ********************************)
(***********************************************************************************)

(*
	OpenAICreateImage[prompt]
		creates an image from the specified prompt.

	OpenAICreateImage[prompt, n]
		creates a list of n images.
*)

Options[OpenAICreateImage] = {
	OpenAIAPIKey :> $OpenAIAPIKey,
	OpenAIUser   :> $OpenAIUser,
	ImageSize    -> Automatic
};

OpenAICreateImage[prompt_String, n_Integer, opts:OptionsPattern[]] :=
	Enclose[
		conformImages[
			OpenAIRequest[
				{"v1", "images", "generations"},
				Select[
					<|
						"prompt" -> prompt,
						"size" -> Confirm@conformImageSizeSpec[OptionValue[ImageSize]],
						"n" -> n,
						"response_format" -> "b64_json"
					|>,
					# =!= Automatic&
				],
				{opts},
				OpenAICreateImage
			]
		],
		"InheritedFailure"
	]

OpenAICreateImage[prompt_String, opts:OptionsPattern[]] :=
	Enclose[
		First@Confirm@OpenAICreateImage[prompt, 1, opts],
		"InheritedFailure"
	]


conformImageSizeSpec[spec_String] := spec
conformImageSizeSpec[Automatic] := Automatic
conformImageSizeSpec[Small] := "256x256"
conformImageSizeSpec[Medium] := "512x512"
conformImageSizeSpec[Large] := "1024x1024"
conformImageSizeSpec[{256,256}] := "256x256"
conformImageSizeSpec[{512,512}] := "512x512"
conformImageSizeSpec[{1024,1024}] := "1024x1024"
conformImageSizeSpec[n_Integer] := conformImageSizeSpec[{n,n}]
conformImageSizeSpec[spec_] :=
	(
		Message[OpenAICreateImage::invImageSize, spec];
		Failure["InvalidImageSize", <|
			"MessageTemplate" :> OpenAICreateImage::invImageSize,
			"MessageParameters" -> {spec},
			"ImageSizeSpecification" -> spec
		|>]
	)



conformImages[resp_] :=
	Enclose[
		conformSingleImage /@ Confirm[resp["data"]],
		invalidCreateImageResponse[resp]&
	]

conformSingleImage[imgResp_] :=
	Enclose[
		Confirm[ImportByteArray[ConfirmBy[BaseDecode[Confirm[imgResp["b64_json"]]], ByteArrayQ]], ImageQ],
		invalidCreateImageResponse[imgResp]&
	]


invalidCreateImageResponse[data_] :=
	(
		Message[OpenAICreateImage::invOpenAICreateImageResponse, data];
		Failure["InvalidOpenAICreateImageResponse", <|
			"MessageTemplate" :> OpenAICreateImage::invOpenAICreateImageResponse,
			"MessageParameters" -> {data}
		|>]
	)


End[];
EndPackage[];

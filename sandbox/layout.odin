package sandbox

import clay "../external/clay-odin"
import "core:c"
import "core:fmt"
import rl "vendor:raylib"


createLayout :: proc(lerpValue: f32) -> clay.ClayArray(clay.RenderCommand) {
	mobileScreen := windowWidth < 750
	clay.BeginLayout()

	if clay.UI(
		clay.ID("OuterContainer"),
		clay.Layout(
			{
				layoutDirection = .TOP_TO_BOTTOM,
				sizing = {clay.SizingGrow({}), clay.SizingGrow({})},
			},
		),
	) {
		// :OUTERCONTAINER
		if clay.UI(
			clay.ID("Header"),
			clay.Layout(
				{
					sizing = {clay.SizingGrow({}), clay.SizingFixed(50)},
					childAlignment = {y = .CENTER},
					childGap = 24,
					padding = {left = 32, right = 32},
				},
			),
		) {
			// :HEADER
			clay.Text("Clay", &headerTextConfig)
			if clay.UI(clay.Layout({sizing = {width = clay.SizingGrow({})}})) {}

			if (!mobileScreen) {
				// examples button
				if clay.UI(
					clay.ID("LinkExamplesOuter"),
					clay.Layout({}),
					clay.Rectangle({color = {0, 0, 0, 0}}),
				) {
					clay.Text(
						"Examples",
						clay.TextConfig(
							{fontId = FONT_ID_BODY_24, fontSize = 24, textColor = {61, 26, 5, 255}},
						),
					)

				}
				// docs button
				if clay.UI(
					clay.ID("LinkDocsOuter"),
					clay.Layout({}),
					clay.Rectangle({color = {0, 0, 0, 0}}),
				) {
					clay.Text(
						"Docs",
						clay.TextConfig(
							{fontId = FONT_ID_BODY_24, fontSize = 24, textColor = {61, 26, 5, 255}},
						),
					)
				}
			}
			if clay.UI(
				clay.ID("LinkGithubOuter"),
				clay.Layout({padding = {16, 16, 6, 6}}),
				clay.BorderOutsideRadius({2, COLOR_RED}, 10),
				clay.Rectangle(
					{
						cornerRadius = clay.CornerRadiusAll(10),
						color = clay.PointerOver(clay.GetElementId(clay.MakeString("LinkGithubOuter"))) ? COLOR_LIGHT_HOVER : COLOR_LIGHT,
					},
				),
			) {
				clay.Text(
					"Github",
					clay.TextConfig(
						{fontId = FONT_ID_BODY_24, fontSize = 24, textColor = {61, 26, 5, 255}},
					),
				)
			}
		}
	}
    // color border at the top
	if clay.UI(
		clay.ID("TopBorder1"),
		clay.Layout({sizing = {clay.SizingGrow({}), clay.SizingFixed(4)}}),
		clay.Rectangle({color = COLOR_TOP_BORDER_5}),
	) {}
	if clay.UI(
		clay.ID("TopBorder2"),
		clay.Layout({sizing = {clay.SizingGrow({}), clay.SizingFixed(4)}}),
		clay.Rectangle({color = COLOR_TOP_BORDER_4}),
	) {}
	if clay.UI(
		clay.ID("TopBorder3"),
		clay.Layout({sizing = {clay.SizingGrow({}), clay.SizingFixed(4)}}),
		clay.Rectangle({color = COLOR_TOP_BORDER_3}),
	) {}
	if clay.UI(
		clay.ID("TopBorder4"),
		clay.Layout({sizing = {clay.SizingGrow({}), clay.SizingFixed(4)}}),
		clay.Rectangle({color = COLOR_TOP_BORDER_2}),
	) {}
	if clay.UI(
		clay.ID("TopBorder5"),
		clay.Layout({sizing = {clay.SizingGrow({}), clay.SizingFixed(4)}}),
		clay.Rectangle({color = COLOR_TOP_BORDER_1}),
	) {}
    // scrollable container TODO: modify to add property inspectors
    if clay.UI(
        clay.ID("ScrollContainerBackgroundRectangle"),
        clay.Scroll({vertical = true}),
        clay.Layout({sizing = {clay.SizingGrow({}), clay.SizingGrow({})}, layoutDirection = clay.LayoutDirection.TOP_TO_BOTTOM}),
        clay.Rectangle({color = COLOR_LIGHT}),
        clay.Border({betweenChildren = {2, COLOR_RED}})
    ) {
        if (!mobileScreen) {
            LandingPageDesktop()
            FeatureBlocksDesktop()
            DeclarativeSyntaxPageDesktop()
            HighPerformancePageDesktop(lerpValue)
            RendererPageDesktop()
        } else {
            LandingPageMobile()
            FeatureBlocksMobile()
            DeclarativeSyntaxPageMobile()
            HighPerformancePageMobile(lerpValue)
            RendererPageMobile()
        }
    }
    // TODO: add viewport container here
    // if clay.UI(clay.ID)

	return clay.EndLayout()
}

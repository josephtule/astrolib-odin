package clay

import "core:c"
import "core:strings"

when ODIN_OS == .Windows {
    foreign import Clay "windows/clay.lib"
} else when ODIN_OS == .Linux {
    foreign import Clay "linux/clay.a"
} else when ODIN_OS == .Darwin {
    when ODIN_ARCH == .arm64 {
        foreign import Clay "macos-arm64/clay.a"
    } else {
        foreign import Clay "macos/clay.a"
    }
} else when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
    foreign import Clay "wasm/clay.o"
}

ElementLocationData :: struct {
    elementLocation: BoundingBox,
    found:           bool,
}

LayoutElementHashMapItem :: struct {
    boundingBox:           BoundingBox,
    elementId:             ElementId,
    layoutElement:         ^LayoutElement,
    onHoverFunction:       proc(elementId: ElementId, pointerInfo: PointerData, userData: rawptr),
    hoverFunctionUserData: rawptr,
    nextIndex:             i32,
    generation:            u32,
    debugData:             rawptr,
}

LayoutElement :: struct {
    childrenOrTextContent: struct #raw_union {
        children:        _LayoutElementChildren,
        textElementData: ^_TextElementData,
    },
    dimensions:            Dimensions,
    minDimensions:         Dimensions,
    layoutConfig:          ^LayoutConfig,
    // elementConfigs:        _ElementConfigArraySlice,
    configsEnabled:        u32,
    id:                    u32,
}

PointerData :: struct {
    position: Vector2,
    state:    PointerDataInteractionState,
}

PointerDataInteractionState :: enum c.int {
    PRESSED_THIS_FRAME,
    PRESSED,
    RELEASED_THIS_FRAME,
    RELEASED,
}

_TextElementData :: struct {
    capacity:      i32,
    length:        i32,
    internalArray: [^]_TextElementData,
}

_LayoutElementChildren :: struct {
    elements: [^]i32,
    length:   u16,
}

// _ElementConfigArraySlice :: struct {
//     length:        i32,
//     internalArray: [^]ElementConfigUnion,
// }


@(link_prefix = "Clay_", default_calling_convention = "c")
foreign Clay {
    OnHover :: proc(onHoverFunction: proc "c" (elementId: ElementId, pointerInfo: PointerData, userData: rawptr), userData: rawptr) ---
    SetQueryScrollOffsetFunction :: proc(queryScrollOffsetFucntion: proc "c" (elementId: u32) -> Vector2) ---
    IsDebugModeEnabled :: proc() -> bool ---
    SetCullingEnabled :: proc(enabled: bool) ---
    SetMaxElementCount :: proc(maxElementCount: i32) ---
    SetMaxMeasureTextCacheWordCount :: proc(maxMeasureTextWordCount: i32) ---
    GetElementLocationData :: proc(id: ElementId) -> ElementLocationData ---
}

@(link_prefix = "Clay_", default_calling_convention = "c", private)
foreign Clay {
    _GetParentElementId :: proc() -> u32 ---
    _GetOpenLayoutElement :: proc() -> ^LayoutElement ---
    _GetHashMapItem :: proc(id: u32) -> LayoutElementHashMapItem ---
}

// ID_LOCAL :: proc(label: string, index: u32 = 0) -> TypedConfig {
//     return {type = ElementConfigType.Id, id = _HashString(MakeString(label), index, _GetParentElementId())}
// }

MakeStringSlice :: proc(label: string) -> StringSlice {
    return StringSlice{chars = raw_data(label), length = cast(c.int)len(label)}
}
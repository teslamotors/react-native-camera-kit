package com.rncamerakit.gallery;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.events.Event;
import com.facebook.react.uimanager.events.RCTEventEmitter;

public class TapCustomButtonEvent extends Event<TapCustomButtonEvent> {

    private final int targetTag;
    private WritableMap event;

    TapCustomButtonEvent(int targetTag) {
        this.targetTag = targetTag;
        event = Arguments.createMap();
        event.putString("id", "onCustomButtonPress");
        init(0);
    }

    @Override
    public String getEventName() {
        return "onCustomButtonPress";
    }

    @Override
    public void dispatch(RCTEventEmitter rctEventEmitter) {
        rctEventEmitter.receiveEvent(targetTag, "onCustomButtonPress", event);
    }
}

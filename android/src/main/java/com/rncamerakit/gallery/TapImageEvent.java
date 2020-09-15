package com.rncamerakit.gallery;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.events.Event;
import com.facebook.react.uimanager.events.RCTEventEmitter;

public class TapImageEvent extends Event<TapImageEvent> {

    private final int targetTag;
    private WritableMap event;

    TapImageEvent(int targetTag, String uri, Integer width, Integer height) {
        this.targetTag = targetTag;
        event = Arguments.createMap();
        event.putString("selected", uri);
        event.putString("id", "onTapImage");
        event.putInt("width", width);
        event.putInt("height", height);
        init(0);
    }

    @Override
    public String getEventName() {
        return "onTapImage";
    }

    @Override
    public void dispatch(RCTEventEmitter rctEventEmitter) {
        rctEventEmitter.receiveEvent(targetTag, "onTapImage", event);
    }
}


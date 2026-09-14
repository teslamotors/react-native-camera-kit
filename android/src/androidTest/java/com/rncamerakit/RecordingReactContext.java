package com.rncamerakit;

import android.content.Context;
import com.facebook.react.bridge.BridgeReactContext;
import com.facebook.react.uimanager.events.EventDispatcher;
import com.facebook.react.uimanager.events.EventDispatcherProvider;
import com.rncamerakit.events.ReadCodeEvent;
import java.lang.reflect.Field;
import java.lang.reflect.Proxy;
import java.util.ArrayList;
import java.util.List;

/** Records the real native event before the JavaScript bridge boundary. */
public final class RecordingReactContext extends BridgeReactContext implements EventDispatcherProvider {
    public final List<String> values = new ArrayList<>();
    private final EventDispatcher dispatcher = (EventDispatcher) Proxy.newProxyInstance(
        EventDispatcher.class.getClassLoader(), new Class<?>[] {EventDispatcher.class},
        (proxy, method, arguments) -> {
            if (method.getName().equals("dispatchEvent")) {
                ReadCodeEvent event = (ReadCodeEvent) arguments[0];
                if (!event.getEventName().equals("topReadCode")) throw new AssertionError(event.getEventName());
                Field value = ReadCodeEvent.class.getDeclaredField("codeStringValue");
                value.setAccessible(true);
                values.add((String) value.get(event));
            }
            return null;
        }
    );

    public RecordingReactContext(Context context) { super(context); }
    @Override public boolean isBridgeless() { return true; }
    @Override public EventDispatcher getEventDispatcher() { return dispatcher; }
}

//
//  foodstepsWidgetLiveActivity.swift
//  foodstepsWidget
//
//  Created by Willy Tanuwijaya on 06/07/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct foodstepsWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct foodstepsWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: foodstepsWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension foodstepsWidgetAttributes {
    fileprivate static var preview: foodstepsWidgetAttributes {
        foodstepsWidgetAttributes(name: "World")
    }
}

extension foodstepsWidgetAttributes.ContentState {
    fileprivate static var smiley: foodstepsWidgetAttributes.ContentState {
        foodstepsWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: foodstepsWidgetAttributes.ContentState {
         foodstepsWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: foodstepsWidgetAttributes.preview) {
   foodstepsWidgetLiveActivity()
} contentStates: {
    foodstepsWidgetAttributes.ContentState.smiley
    foodstepsWidgetAttributes.ContentState.starEyes
}

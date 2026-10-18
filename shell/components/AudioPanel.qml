pragma ComponentBehavior: Bound
import Quickshell.Services.Pipewire
import "../LayoutPolicy.js" as Policy

AudioControls {
    id: panel
    sink: Pipewire.defaultAudioSink
    backendAvailable: Pipewire.ready
    devices: Pipewire.nodes.values.filter(node => node.ready && node.audio && node.isSink && !node.isStream)
    streams: Pipewire.nodes.values.filter(node => node.ready && node.audio && node.isStream && !node.isSink && Policy.playbackStream(node.properties["media.class"]))
    onOutputRequested: node => { Pipewire.preferredDefaultAudioSink = node; }
    // Track candidates before filtering so audio/properties can become ready.
    PwObjectTracker { objects: Pipewire.nodes.values }
}

#!/usr/bin/env python3
from pathlib import Path
import subprocess
import tempfile
root=Path(__file__).resolve().parents[1]
src=root/'DynamicNotch'
common=['Core/NotchEngine/NotchEngine.swift','Core/NotchEngine/Models/NotchModel.swift','Core/NotchEngine/Models/NotchState.swift','Core/NotchEngine/Protocols/NotchContentProtocol.swift','Core/NotchEngine/Protocols/DynamicIslandCustomizable.swift','Features/Notch/NotchAnimations.swift']
flags=['xcrun','swiftc','-swift-version','5','-default-isolation','MainActor','-parse-as-library','-target','arm64-apple-macosx26.0']
output=Path(tempfile.mkdtemp(prefix='dynamicnotch-activities-'))
for name, extra in [('LiveActivityPairTests',[]),('HomePageSessionIntegration',['Features/Notch/ViewModels/NotchViewModel.swift','Features/HomePage/Models/HomePageSessionMemory.swift','Core/NotchEngine/Models/NotchExpandInteraction.swift','Core/NotchEngine/Models/NotchCollapseInteraction.swift','Shared/UI/Modifiers/SwipeFeedbackMetrics.swift'])]:
 binary=output/name
 subprocess.run(flags+[str(src/p) for p in common+extra]+[str(root/'tests/standalone'/f'{name}.swift'),'-o',str(binary)],check=True)
 subprocess.run([str(binary)],check=True)

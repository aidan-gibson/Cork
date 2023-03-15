//
//  Update Packages.swift
//  Cork
//
//  Created by David Bureš on 09.03.2023.
//

import SwiftUI

struct UpdatePackagesView: View
{
    @Binding var isShowingSheet: Bool

    @State var packageUpdatingStage: PackageUpdatingStage = .updating
    @State var packageUpdatingStep: PackageUpdatingProcessSteps = .ready

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var updateProgressTracker: UpdateProgressTracker
    @EnvironmentObject var outdatedPackageTracker: OutdatedPackageTracker

    var body: some View
    {
        VStack(alignment: .leading, spacing: 10)
        {
            switch packageUpdatingStage
            {
            case .updating:
                ProgressView(value: updateProgressTracker.updateProgress, total: 10)
                {
                    switch packageUpdatingStep
                    {
                    case .ready:
                        Text("Ready")
                            .onAppear
                            {
                                packageUpdatingStep = .checkingForUpdates
                            }
                    case .checkingForUpdates:
                        Text("Fetching updates...")
                            .onAppear
                            {
                                Task(priority: .userInitiated)
                                {
                                    let updateAvailability = await updatePackages(updateProgressTracker, appState: appState)
                                    
                                    if updateAvailability == .noUpdatesAvailable
                                    {
                                        packageUpdatingStage = .noUpdatesAvailable
                                    }
                                    else
                                    {
                                        packageUpdatingStep = .updatingPackages
                                    }
                                }
                            }
                    case .updatingPackages:
                        Text("Updating packages...")
                            .onAppear
                            {
                                Task(priority: .userInitiated)
                                {
                                    await upgradePackages(updateProgressTracker, appState: appState, outdatedPackageTracker: outdatedPackageTracker)

                                    if updateProgressTracker.errors.isEmpty
                                    {
                                        packageUpdatingStage = .finished
                                    }
                                    else
                                    {
                                        packageUpdatingStage = .erroredOut
                                    }
                                }
                            }
                    case .finished:
                        Text("Done")
                            .onAppear
                            {
                                packageUpdatingStep = .finished
                            }
                    }
                }
                .fixedSize()

            case .noUpdatesAvailable:
                DisappearableSheet(isShowingSheet: $isShowingSheet)
                {
                    ComplexWithIcon(systemName: "checkmark.seal")
                    {
                        HeadlineWithSubheadline(headline: "No updates available", subheadline: "You're all up to date", alignment: .leading)
                            .fixedSize()
                    }
                }

            case .finished:
                DisappearableSheet(isShowingSheet: $isShowingSheet)
                {
                    ComplexWithIcon(systemName: "checkmark.seal")
                    {
                        HeadlineWithSubheadline(headline: "Sucessfully upgraded packages", subheadline: "There were no errors", alignment: .leading)
                            .fixedSize()
                    }
                }

            case .erroredOut:
                ComplexWithIcon(systemName: "xmark.seal")
                {
                    VStack(alignment: .leading, spacing: 5)
                    {
                        HeadlineWithSubheadline(headline: "Packages updated with errors", subheadline: "There were some errors during updating.\nCheck below for more information", alignment: .leading)
                        List
                        {
                            ForEach(updateProgressTracker.errors, id: \.self)
                            { error in
                                Text(error)
                            }
                        }
                        HStack
                        {
                            Spacer()
                            DismissSheetButton(isShowingSheet: $appState.isShowingUpdateSheet)
                        }
                    }
                    .fixedSize()
                }
            }
        }
        .padding()
    }
}

//
//  ItemListCoordinator.swift
//  BookPlayer
//
//  Created by Gianni Carlo on 9/9/21.
//  Copyright © 2021 Tortuga Power. All rights reserved.
//

import BookPlayerKit
import Combine
import UIKit
import UniformTypeIdentifiers

enum ItemListActionRoutes {
  case downloadBook(_ url: URL)
  case newImportOperation(_ operation: ImportOperation)
  case importOperationFinished(_ urls: [URL])
  case reloadItems(_ pageSizePadding: Int)
}

class ItemListCoordinator: Coordinator {
  public var onAction: Transition<ItemListActionRoutes>?
  let playerManager: PlayerManagerProtocol
  let libraryService: LibraryServiceProtocol
  let playbackService: PlaybackServiceProtocol
  let syncService: SyncServiceProtocol

  weak var documentPickerDelegate: UIDocumentPickerDelegate?

  init(
    navigationController: UINavigationController,
    playerManager: PlayerManagerProtocol,
    libraryService: LibraryServiceProtocol,
    playbackService: PlaybackServiceProtocol,
    syncService: SyncServiceProtocol
  ) {
    self.playerManager = playerManager
    self.libraryService = libraryService
    self.playbackService = playbackService
    self.syncService = syncService

    super.init(navigationController: navigationController,
               flowType: .push)
  }

  override func start() {
    fatalError("ItemListCoordinator is an abstract class, override this function in the subclass")
  }

  override func getMainCoordinator() -> MainCoordinator? {
    switch self.parentCoordinator {
    case let mainCoordinator as MainCoordinator:
      return mainCoordinator
    case let listCoordinator as ItemListCoordinator:
      return listCoordinator.getMainCoordinator()
    default:
      return nil
    }
  }

  func showFolder(_ relativePath: String) {
    let child = FolderListCoordinator(
      navigationController: navigationController,
      folderRelativePath: relativePath,
      playerManager: playerManager,
      libraryService: libraryService,
      playbackService: playbackService,
      syncService: syncService
    )
    self.childCoordinators.append(child)
    child.parentCoordinator = self
    child.start()
  }

  func showPlayer() {
    let playerCoordinator = PlayerCoordinator(
      playerManager: self.playerManager,
      libraryService: self.libraryService,
      syncService: self.syncService,
      presentingViewController: self.navigationController
    )
    playerCoordinator.parentCoordinator = self
    self.childCoordinators.append(playerCoordinator)
    playerCoordinator.start()
  }

  func showSearchList(at relativePath: String?, placeholderTitle: String) {
    let coordinator = SearchListCoordinator(
      navigationController: navigationController,
      placeholderTitle: placeholderTitle,
      folderRelativePath: relativePath,
      playerManager: playerManager,
      libraryService: libraryService,
      playbackService: playbackService,
      syncService: syncService
    )
    coordinator.start()
  }

  func loadPlayer(_ relativePath: String) {
    AppDelegate.shared?.loadPlayer(
      relativePath,
      autoplay: true,
      showPlayer: { [weak self] in
        self?.showPlayer()
      },
      alertPresenter: self
    )
  }

  func showMiniPlayer(flag: Bool) {
    getMainCoordinator()?.showMiniPlayer(flag)
  }

  func syncList() {
    fatalError("ItemListCoordinator is an abstract class, override this function in the subclass")
  }
}

extension ItemListCoordinator {
  func showDocumentPicker() {
    let providerList = UIDocumentPickerViewController(
      forOpeningContentTypes: [
        UTType.audio,
        UTType.movie,
        UTType.zip,
        UTType.folder
      ],
      asCopy: true
    )

    providerList.delegate = self.documentPickerDelegate
    providerList.allowsMultipleSelection = true

    UIApplication.shared.isIdleTimerDisabled = true

    self.presentingViewController?.present(providerList, animated: true, completion: nil)
  }

  func showExportController(for items: [SimpleLibraryItem]) {
    let providers = items.map { BookActivityItemProvider($0) }

    let shareController = UIActivityViewController(activityItems: providers, applicationActivities: nil)
    shareController.excludedActivityTypes = [.copyToPasteboard]

    self.navigationController.present(shareController, animated: true, completion: nil)
  }

  func reloadItemsWithPadding(padding: Int = 0) {
    // Reload all preceding screens too
    if let coordinator = self.parentCoordinator as? ItemListCoordinator {
      coordinator.reloadItemsWithPadding(padding: padding)
    }

    self.onAction?(.reloadItems(padding))
  }

  func showItemDetails(_ item: SimpleLibraryItem) {
    let coordinator = ItemDetailsCoordinator(
      item: item,
      libraryService: libraryService,
      navigationController: navigationController
    )

    coordinator.onFinish = { route in
      switch route {
      case .infoUpdated:
        self.reloadItemsWithPadding()
      }
    }

    coordinator.start()
  }

  func showItemSelectionScreen(
    availableItems: [SimpleLibraryItem],
    selectionHandler: @escaping (SimpleLibraryItem) -> Void
  ) {
    let vc = ItemSelectionViewController()
    vc.items = availableItems
    vc.onItemSelected = selectionHandler

    let nav = AppNavigationController(rootViewController: vc)
    self.navigationController.present(nav, animated: true, completion: nil)
  }
}

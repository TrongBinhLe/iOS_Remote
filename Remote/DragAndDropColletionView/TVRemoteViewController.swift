//
//  TVRemoteViewController.swift
//  Remote
//
//  Created by admin on 09/08/2023.
//

//  TVRemoteControlNewY23ViewController.swift - TVController2
//  Copyright © 2023 Samsung Electronics. All rights reserved.
//
//  Created by Nguyen Khanh Toan on 11/05/2023.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa
import Lottie

// swiftlint:disable type_body_length
class TVRemoteControlNewY23ViewController: TVRemoteBaseViewController {
    private let ocfRemoteClient: TVOCFRemoteInterface = TVOCFRemoteClient()
    
    var currentContainerHeight: CGFloat = RemotePanelMode.defaultHeight
    var maximumContainerHeight: CGFloat = UIScreen.main.bounds.height
    
    var containerViewHeightConstraint: NSLayoutConstraint?
    var touchPadContainerHeightConstraint: NSLayoutConstraint?
    
    private var tvStatus: TVStatusType = .tvOn
    private var isD2dSupport: Bool = false
    private var pointerStatus: Bool = false
    
    lazy var viewModel: TVRemoteControlNewY23ViewModel = {
        let vm = TVRemoteControlNewY23ViewModel(remoteVM)
        vm.delegate = self
        return vm
    }()
    
    let themeVM: RemoteNewY23ThemeViewModel = RemoteNewY23ThemeViewModel()
    
    private var bottomAreaHeight: CGFloat? {
        let window = UIApplication.shared.windows.filter { $0.isKeyWindow }.first
        return window?.safeAreaInsets.bottom
    }
    
    lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isScrollEnabled = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.roundAuto(toFit: .absolute(16))
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = CGSize(width: 1, height: -1)
        view.layer.shadowRadius = 6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var contentView: UIView = {
        let view = UIView()
        view.roundAuto(toFit: .absolute(16))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let tapDimmedViewGesture = UITapGestureRecognizer()
    
    lazy var dimmedView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapDimmedViewGesture)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let dragIcon: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "drag_ic", in: Bundle.TV, compatibleWith: nil)
        view.contentMode = .center
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()
    
    let dragIconView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "drag_ic", in: Bundle.TV, compatibleWith: nil)
        view.contentMode = .center
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()
    
    lazy var padView: PadView = {
        let view = PadView(themeVM: self.themeVM)
        view.centerButton.addGestureRecognizer(centerLongPressGesture)
        view.topWayButton.addGestureRecognizer(padViewTopPressGesture)
        view.leftWayButton.addGestureRecognizer(padViewLeftPressGesture)
        view.bottomWayButton.addGestureRecognizer(padViewBottomPressGesture)
        view.rightWayButton.addGestureRecognizer(padViewRightPressGesture)
        view.isUserInteractionEnabled = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let powerLongPressGesture = UILongPressGestureRecognizer()
    let returnLongPressGesture = UILongPressGestureRecognizer()
    
    lazy var powerButton: RemoteKeyButton = {
        let button = RemoteKeyButton()
        button.keyLabel = "KEY_POWER"
        button.eventName = "Power"
        button.eventId = "TV8120"
        button.setImage(UIImage(named: "icon_a_power", in: Bundle.TV, compatibleWith: nil), for: .normal)
        button.roundAuto()
        button.addGestureRecognizer(powerLongPressGesture)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let searchButton: RemoteKeyButton = {
        let button = RemoteKeyButton()
        button.eventName = "Search"
        button.eventId = "TV8141"
        button.roundAuto()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let optionMenuButton: RemoteKeyButton = {
        let button = RemoteKeyButton()
        button.eventName = "Information"
        button.eventId = "TV0005"
        button.roundAuto()
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var optionMenuStackView = HStackView {
        searchButton
        optionMenuButton
    }
    
    lazy var topView = UIView.wrap {
        powerButton
        optionMenuStackView
    }
    
    lazy var optionsDialog: RemoteNewY23MoreView = {
        let view = RemoteNewY23MoreView()
        return view
    }()
    
    lazy var settingButton: RemoteKeyButton = {
        let button = RemoteKeyButton()
        button.keyLabel = "KEY_MORE"
        button.eventId = "TV8121"
        button.eventName = "Settings/123/option"
        button.roundAuto()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.hideBackgroundImageView = false
        return button
    }()
    
    lazy var voiceLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressVoiceButton(_:)))
    lazy var multiViewLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
    lazy var centerLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleCenterLongPress(_:)))
    lazy var nextLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressNextButton(_:)))
    lazy var padViewLeftPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressPadViewLeftButton(_:)))
    lazy var padViewRightPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressPadViewRightButton(_:)))
    lazy var padViewTopPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressPadViewTopButton(_:)))
    lazy var padViewBottomPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressPadViewBottomButton(_:)))
    
    lazy var voiceButton: RemoteKeyButton = {
        let button = RemoteKeyButton()
        button.keyLabel = "KEY_BT_VOICE"
        button.eventId = "TV8123"
        button.eventName = "Voice"
        button.roundAuto()
        button.addGestureRecognizer(voiceLongPressGesture)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.hideBackgroundImageView = false
        return button
    }()
    
    lazy var extraButton: RemoteKeyButton = {
        let button = RemoteKeyButton()
        button.keyLabel = "KEY_COLOR"
        button.eventId = "TV1012"
        button.eventName = "Option"
        button.setImage(
            UIImage(named: "icon_c_colorkey_only", in: Bundle.TV, compatibleWith: nil),
            for: .normal
        )
        button.roundAuto()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.hideBackgroundImageView = false
        return button
    }()
    
    lazy var settingView = UIView.wrap {
        settingViewContainer
    }
    
    lazy var settingViewContainer = UIView.wrap {
        settingButton
        stackViewFunctions
        voiceButton
        extraButton
    }
    
    lazy var backButton: RemoteKeyButton = {
        let button = RemoteKeyButton()
        button.keyLabel = "KEY_RETURN"
        button.eventId = "TV8125"
        button.eventName = "Return"
        button.roundAuto()
        button.addGestureRecognizer(returnLongPressGesture)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.hideBackgroundImageView = false
        return button
    }()
    
    lazy var homeButton: RemoteKeyButton = {
        let button = RemoteKeyButton()
        button.keyLabel = "KEY_HOME"
        button.eventId = "TV8126"
        button.eventName = "Home"
        button.setImage(
            UIImage(named: "icon_c_home", in: Bundle.TV, compatibleWith: nil),
            for: .normal
        )
        button.roundAuto()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.hideBackgroundImageView = false
        return button
    }()
    
    lazy var nextButton: RemoteKeyButton = {
        let button = RemoteKeyButton()
        button.keyLabel = "KEY_PLAY_BACK"
        button.eventId = "TV8127"
        button.eventName = "Play pause"
        button.roundAuto()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.hideBackgroundImageView = false
        button.addGestureRecognizer(nextLongPressGesture)
        return button
    }()
    
    lazy var funtionalView = UIView.wrap {
        backButton
        homeButton
        nextButton
    }
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = .leastNonzeroMagnitude
        layout.minimumInteritemSpacing = .leastNonzeroMagnitude
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.register(cellTypes: [
            PageControlCell.self,
            PageNumberCell.self,
            PageAppCell.self,
            PageCell.self,
            PageSoundAndAppCell.self,
            PageABCDCell.self
        ])
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.backgroundColor = .clear
        collection.isPagingEnabled = true
        collection.showsHorizontalScrollIndicator = false
        return collection
    }()
    
    lazy var collectionContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.addSubview(collectionView)
        return view
    }()
    
    lazy var pageControlView: UIPageControl = {
        var pageControl = UIPageControl()
        pageControl.isUserInteractionEnabled = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }()
    
    lazy var pageControlContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.addSubview(pageControlView)
        return view
    }()
    
    lazy var bottomView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionContainerView)
        view.addSubview(pageControlContainerView)
        return view
    }()
    
    let separator1View: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let separator2View: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var stackView = VStackView {
        topView
        settingView
        separator1View
        padView
        separator2View
        funtionalView
        bottomView
    }
    
    let singlePowerView: SinglePowerView = {
        let view = SinglePowerView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var rotationButton: RemoteKeyButton = {
        let view = RemoteKeyButton()
        view.keyLabel = "KEY_ROTATE_PANEL"
        view.eventName = "Rotation"
        view.eventId = "TV8122"
        view.roundAuto()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.sizeItem(60)
        view.hideBackgroundImageView = false
        return view
    }()
    
    lazy var multiViewButton: RemoteKeyButton = {
        let view = RemoteKeyButton()
        view.keyLabel = "KEY_MULTI_VIEW"
        view.eventName = "MultiView"
        view.eventId = "TV0940"
        view.roundAuto()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.sizeItem(60)
        view.addGestureRecognizer(multiViewLongPressGesture)
        view.hideBackgroundImageView = false
        return view
    }()
    
    lazy var theSeroButton: RemoteKeyButton = {
        let view = RemoteKeyButton()
        view.keyLabel = "KEY_AOD"
        view.eventName = "TheSero"
        view.eventId = "TV0111"
        view.roundAuto()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.sizeItem(60)
        view.hideBackgroundImageView = false
        return view
    }()
    
    lazy var keyStoneButton: RemoteKeyButton = {
        let view = RemoteKeyButton()
        view.keyLabel = "KEY_KEYSTONE"
        view.eventName = "Keystone"
        view.eventId = "TV8135"
        view.roundAuto()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.sizeItem(60)
        view.hideBackgroundImageView = false
        return view
    }()
    
    lazy var scaleAndMoveButton: RemoteKeyButton = {
        let view = RemoteKeyButton()
        view.keyLabel = "KEY_SCALE_MOVE"
        view.eventName = "Scale and Move Screen"
        view.eventId = "TV8134"
        view.roundAuto()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.sizeItem(60)
        view.hideBackgroundImageView = false
        return view
    }()
    
    lazy var themesButton: RemoteKeyButton = {
        let view = RemoteKeyButton()
        view.keyLabel = "KEY_AMBIENT"
        view.eventName = "Themes"
        view.eventId = "TV0944"
        view.roundAuto()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.sizeItem(60)
        view.hideBackgroundImageView = false
        return view
    }()
    
    lazy var screenRotationButton: RemoteKeyButton = {
        let view = RemoteKeyButton()
        view.keyLabel = "KEY_ROTATE_PANEL"
        view.eventName = "Rotation"
        view.eventId = "TV8112"
        view.roundAuto()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.sizeItem(60)
        view.hideBackgroundImageView = false
        return view
    }()
    
    lazy var serviceButton: RemoteKeyButton = {
        let view = RemoteKeyButton()
        view.keyLabel = "KEY_MULTI_VIEW"
        view.eventName = "MultiView"
        view.eventId = "TV0940"
        view.roundAuto()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.sizeItem(60)
        view.addGestureRecognizer(multiViewLongPressGesture)
        view.hideBackgroundImageView = false
        return view
    }()
    
    lazy var guideArtModeButtonView: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.3)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(guideBackgroundWhiteView)
        view.addSubview(guidePowerButton)
        view.isHidden = true
        return view
    }()
    
    lazy var guideBackgroundWhiteView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(guideLabel)
        return view
    }()
    
    lazy var guideLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.textAlignment = .natural
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var guideImageView: UIImageView = {
        let view = UIImageView()
        let image = UIImage(named: "core_first_tooltip_horn", in: Bundle.TV, compatibleWith: nil) ?? UIImage()
        let newImage = image.rotate(radians: .pi/2) // Rotate 90 degrees
        view.image = newImage
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var guidePowerButton: RemoteKeyButton = {
        let button = RemoteKeyButton()
        button.keyLabel = "KEY_POWER"
        button.eventName = "Power"
        button.eventId = "TV0054"
        button.setImage(UIImage(named: "icon_a_power", in: Bundle.TV, compatibleWith: nil)?.withTintColor(.black), for: .normal)
        button.roundAuto()
        button.backgroundColor = .white
        button.backColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var stackViewFunctions: UIStackView = {
        var stk = UIStackView(arrangedSubviews: [rotationButton, multiViewButton, theSeroButton, keyStoneButton, scaleAndMoveButton, themesButton, screenRotationButton, serviceButton])
        stk.spacing = 0
        stk.alignment = .center
        stk.distribution = .fill
        stk.axis = .horizontal
        stk.translatesAutoresizingMaskIntoConstraints = false
        return stk
    }()
    
    var sourceAndAppView: AppAndSourceView?
    
    lazy var appEditingView: AppEditingView = {
        let appViewEditing = AppEditingView()
        appViewEditing.isHidden = true
        appViewEditing.translatesAutoresizingMaskIntoConstraints = false
        return appViewEditing
    }()
    
    var state: RemotePanelMode = .normal
    var appPageState: AppPageMode = .normal
    
    var pageLayouts: [PageCellViewModel] = [
        .abcd,
        .numPad,
        .tvControl,
        .tvControlAndApplicationConfig,
        .applicationConfig
    ].map({
        PageCellViewModel(content: $0.description, type: $0)
    }) {
        didSet {
            collectionView.reloadData()
        }
    }
    
    private var quickOption: QuickOption?
    
    var widthCollectionViewContraint: NSLayoutConstraint!
    var topDragIconContraint: NSLayoutConstraint!
    var remoteGestureHelper: RemoteGestureHelper?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        
        getRotationAccessoryStatus()
        layouts()
        setupPanGesture()
        configCollectionView()
        configNavigateGuide()
        viewModel.setObserver(with: disposables, theme: themeVM)
        setStyleObserver()
        initReactiveAction()
        configVibration()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func setStyleObserver() {
        disposables += themeVM.theme.producer.startWithValues { [weak self] _ in
            guard let self = self else { return }
            self.updateIconColors()
            self.updateThemeColors()
        }
    }
    
    private func updateThemeColors() {
        contentView.backgroundColor = themeVM.resolve(\.backgroundColor)
        dimmedView.backgroundColor = themeVM.resolve(\.dimBG)
        bottomView.backgroundColor = themeVM.resolve(\.customAreaBG)
        [
            settingButton,
            voiceButton,
            nextButton,
            extraButton,
            homeButton,
            backButton,
            multiViewButton,
            theSeroButton,
            keyStoneButton,
            scaleAndMoveButton,
            themesButton,
            screenRotationButton,
            serviceButton,
            extraButton,
            singlePowerView.powerButton,
            rotationButton
        ]
            .compactMap({ $0 })
            .forEach({
                $0.backgroundImageView.image = themeVM.resolve(\.backgroundButtonImage)
                $0.backColor = .clear
                $0.tintColor = themeVM.resolve(\.textColor)
                $0.backgroundColor = .clear //themeVM.resolve(\.backgroundColor)
            })
    }
    
    private func updateIconColors() {
        pageControlView.currentPageIndicatorTintColor = themeVM.resolve(\.doneButtonColor)
        optionsDialog.remoteOptionLabel.textColor = themeVM.resolve(\.doneButtonColor)
        optionsDialog.howToUseLabel.textColor = themeVM.resolve(\.doneButtonColor)
        optionsDialog.backgroundView.backgroundColor = themeVM.resolve(\.btnBG)
        searchButton.setImage(themeVM.resolve(\.settingMenuIcon), for: .normal)
        optionMenuButton.setImage(themeVM.resolve(\.optionMenuIcon), for: .normal)
        dragIcon.tintColor = themeVM.resolve(\.btnBG)
        voiceButton.setImage(themeVM.resolve(\.voiceIcon), for: .normal)
        settingButton.setImage(themeVM.resolve(\.settingIcon), for: .normal)
        backButton.setImage(themeVM.resolve(\.returnIcon), for: .normal)
        nextButton.setImage(themeVM.resolve(\.playbackIcon), for: .normal)
        //functions
        rotationButton.setImage(themeVM.resolve(\.rotationIcon), for: .normal)
        multiViewButton.setImage(themeVM.resolve(\.multiViewIcon), for: .normal)
        theSeroButton.setImage(themeVM.resolve(\.theSeroIcon), for: .normal)
        keyStoneButton.setImage(themeVM.resolve(\.keyStoneIcon), for: .normal)
        scaleAndMoveButton.setImage(themeVM.resolve(\.scaleAndMoveIcon), for: .normal)
        themesButton.setImage(themeVM.resolve(\.themesIcon), for: .normal)
        screenRotationButton.setImage(themeVM.resolve(\.screenRotationIcon), for: .normal)
        serviceButton.setImage(themeVM.resolve(\.serviceIcon), for: .normal)
        if self.viewModel.tvCategoryType == .frameTV {
            singlePowerView.powerButton.setImage(themeVM.resolve(\.iconArtModePower), for: .normal)
            powerButton.setImage(themeVM.resolve(\.iconArtModePower), for: .normal)
            guidePowerButton.setImage(UIImage(named: "icon_a_artmode", in: Bundle.TV, compatibleWith: nil)?.withTintColor(.black), for: .normal)
        } else {
            singlePowerView.powerButton.setImage(UIImage(named: "icon_a_power", in: Bundle.TV, compatibleWith: nil), for: .normal)
            powerButton.setImage(UIImage(named: "icon_a_power", in: Bundle.TV, compatibleWith: nil), for: .normal)
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let rotationAccessoryStatus = TVDeviceManager.rotationAccessoryStatus.value
        switch gesture.state {
        case .began:
            if rotationAccessoryStatus != .notReady {
                CLLogInfo(.REMOTE, "Send key: KEY_ROTATE_PANEL")
                viewModel.remoteGestureHelper.addHapticEffect()
                remoteVM.sendClickEvent("KEY_ROTATE_PANEL")
            }
        case .ended:
            if rotationAccessoryStatus == .notReady {
                handleTap()
            }
        default:
            break
        }
    }
    
    @objc private func handleTap() {
        CLLogInfo(.REMOTE, "Send key: KEY_MULTI_VIEW")
        RemoteAnalytics.send(RemotePanelMode.remoteScreenID, "TV0940")
        viewModel.remoteGestureHelper.addHapticEffect()
        remoteVM.sendClickEvent("KEY_MULTI_VIEW")
    }
    
    @objc private func handleCenterLongPress(_ gesture: UILongPressGestureRecognizer) {
        viewModel.remoteGestureHelper.longPressAndRelease(key: .KEY_OK, gesture)
    }
    
    @objc private func didLongPressPadViewLeftButton(_ gesture: UILongPressGestureRecognizer) {
        viewModel.remoteGestureHelper.longPressAndRelease(key: .KEY_LEFT, gesture)
    }
    @objc private func didLongPressPadViewRightButton(_ gesture: UILongPressGestureRecognizer) {
        viewModel.remoteGestureHelper.longPressAndRelease(key: .KEY_RIGHT, gesture)
    }
    @objc private func didLongPressPadViewTopButton(_ gesture: UILongPressGestureRecognizer) {
        viewModel.remoteGestureHelper.longPressAndRelease(key: .KEY_UP, gesture)
    }
    @objc private func didLongPressPadViewBottomButton(_ gesture: UILongPressGestureRecognizer) {
        viewModel.remoteGestureHelper.longPressAndRelease(key: .KEY_DOWN, gesture)
    }
    
    @objc
    private func didLongPressNextButton(_ gesture: UILongPressGestureRecognizer) {
        viewModel.remoteGestureHelper.longPressAndRelease(key: .KEY_PLAY_BACK, gesture)
    }
    
    // swiftlint:disable function_body_length
    private func initReactiveAction() {
        remoteGestureHelper = RemoteGestureHelper(remoteVM)
        
        // Actions
        disposables += singlePowerView.powerButton.reactive.controlEvents(.touchUpInside)
            .throttle(1.0, on: QueueScheduler.main)
            .observeValues { [weak self] sender in
                guard let `self` = self else { return }
                switch self.tvStatus {
                case .tvOff:
                    if self.viewModel.tvCategoryType == .frameTV {
                        self.viewModel.sendClickEvent(sender)
                        self.singlePowerView.powerButton.startSpinner()
                    } else {
                        self.singlePowerView.powerButton.startSpinner()
                        self.ocfRemoteClient.setSwitch(value: true)
                        RemoteAnalytics.send(RemotePanelMode.remoteScreenID, sender.eventId)
                    }
                case .disconnect:
                    break
                default:
                    if TVDeviceManager.shared?.tvPowerState == false {
                        if self.viewModel.tvCategoryType == .frameTV {
                            self.viewModel.sendClickEvent(sender)
                        } else {
                            self.singlePowerView.powerButton.startSpinner()
                            self.ocfRemoteClient.setSwitch(value: true)
                            RemoteAnalytics.send(RemotePanelMode.remoteScreenID, sender.eventId)
                        }
                    }
                }
            }
        
        disposables += singlePowerView.longPressGesture.reactive.stateChanged
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] _ in
                guard let `self` = self else { return }
                switch self.tvStatus {
                case .tvOff:
                    self.singlePowerView.powerButton.startSpinner()
                    self.ocfRemoteClient.setSwitch(value: true)
                    RemoteAnalytics.send(RemotePanelMode.remoteScreenID, self.singlePowerView.powerButton.eventId)
                case .disconnect:
                    break
                default:
                    if TVDeviceManager.shared?.tvPowerState == false {
                        self.singlePowerView.powerButton.startSpinner()
                        self.ocfRemoteClient.setSwitch(value: true)
                        RemoteAnalytics.send(RemotePanelMode.remoteScreenID, self.singlePowerView.powerButton.eventId)
                    }
                }
            })
        
        disposables += powerButton.reactive.controlEvents(.touchUpInside)
            .throttle(1.0, on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                guard let `self` = self else { return }
                
                switch self.tvStatus {
                case .disconnect, .tvOff:
                    break
                case .tvOn:
                    if self.viewModel.tvCategoryType == .frameTV {
                        self.viewModel.sendClickEvent(sender)
                    } else {
                        self.powerButton.startSpinner()
                        self.ocfRemoteClient.setSwitch(value: false)
                        RemoteAnalytics.send(RemotePanelMode.remoteScreenID, sender.eventId)
                    }
                default:
                    if TVDeviceManager.shared?.tvPowerState == true {
                        if self.viewModel.tvCategoryType == .frameTV {
                            self.viewModel.sendClickEvent(sender)
                        } else {
                            self.powerButton.startSpinner()
                            self.ocfRemoteClient.setSwitch(value: false)
                            RemoteAnalytics.send(RemotePanelMode.remoteScreenID, sender.eventId)
                        }
                    }
                }
            })
        
        disposables += guidePowerButton.reactive.controlEvents(.touchUpInside)
            .throttle(1.0, on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                guard let `self` = self else { return }
                
                switch self.tvStatus {
                case .disconnect, .tvOff:
                    break
                case .tvOn:
                    if self.viewModel.tvCategoryType == .frameTV {
                        self.viewModel.sendClickEvent(sender)
                    } else {
                        self.powerButton.startSpinner()
                        self.ocfRemoteClient.setSwitch(value: false)
                        RemoteAnalytics.send(RemotePanelMode.remoteScreenID, sender.eventId)
                    }
                default:
                    if TVDeviceManager.shared?.tvPowerState == true {
                        if self.viewModel.tvCategoryType == .frameTV {
                            self.viewModel.sendClickEvent(sender)
                        } else {
                            self.powerButton.startSpinner()
                            self.ocfRemoteClient.setSwitch(value: false)
                            RemoteAnalytics.send(RemotePanelMode.remoteScreenID, sender.eventId)
                        }
                    }
                }
            })
        
        disposables += powerLongPressGesture.reactive.stateChanged
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                guard let `self` = self else { return }
                
                switch self.tvStatus {
                case .disconnect, .tvOff:
                    break
                case .tvOn:
                    if self.viewModel.tvCategoryType == .frameTV {
                        self.showPopupTurnOffFrameTV()
                    } else {
                        self.powerButton.startSpinner()
                        self.ocfRemoteClient.setSwitch(value: false)
                        RemoteAnalytics.send(RemotePanelMode.remoteScreenID, self.powerButton.eventId)
                    }
                default:
                    if TVDeviceManager.shared?.tvPowerState == true {
                        if self.viewModel.tvCategoryType == .frameTV {
                            self.showPopupTurnOffFrameTV()
                        } else {
                            self.powerButton.startSpinner()
                            self.ocfRemoteClient.setSwitch(value: false)
                            RemoteAnalytics.send(RemotePanelMode.remoteScreenID, self.powerButton.eventId)
                        }
                    }
                }
            })
        
        setupTapButtonAction()

        disposables += tapDimmedViewGesture.reactive.stateChanged
            .observeValues({ [weak self] _ in
                guard let `self` = self else { return }
                RemoteAnalytics.send("TV031", "TV0280")
                self.animateDismissView()
            })
        
        disposables += optionsDialog.tapRemoteOptionGesture.reactive.stateChanged
            .observeValues({ [weak self] _ in
                guard let `self` = self else { return }
                RemoteAnalytics.send("TV033", "TV0191")
                self.showRemoteOptions()
                self.optionsDialog.removeFromSuperview()
            })
        
        disposables += optionsDialog.tapHowToUseGesture.reactive.stateChanged
            .observeValues({ [weak self] _ in
                guard let `self` = self else { return }
                RemoteAnalytics.send("TV033", "TV0192")
                self.showRemoteHowToUse()
                self.optionsDialog.removeFromSuperview()
            })
        
        disposables += returnLongPressGesture.reactive.stateChanged
            .throttle(0.3, on: QueueScheduler.main)
            .observeValues({ [weak self] _ in
                guard let `self` = self else { return }
                self.remoteVM.sendClickEvent(RemoteKeys.kKeyReturn_LongP)
            })
        
        disposables += appEditingView.selectAllTapGesture.reactive.stateChanged
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] _ in
                guard let `self` = self else { return }
                RemoteAnalytics.send("TV029", "TV0272")
                RemoteGlobalAction.shared().selectAllItemsSignal.input.send(value: self.viewModel.pageType)
                self.appEditingView.switchMode(true)
            })
        
        disposables += appEditingView.unSelectAllTapGesture.reactive.stateChanged
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] _ in
                guard let `self` = self else { return }
                RemoteAnalytics.send("TV029", "TV0273")
                RemoteGlobalAction.shared().deselectItemsSignal.input.send(value: self.viewModel.pageType)
                self.appEditingView.switchMode(false)
            })
        
        disposables += appEditingView.removeTapGesture.reactive.stateChanged
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] _ in
                guard let `self` = self else { return }
                RemoteGlobalAction.shared().deleteItemsSignal.input.send(value: self.viewModel.pageType)
                self.appEditingView.switchMode(false)
                self.resetCustomAreaToNormal()
            })
        
        disposables += appEditingView.outSideTapGesture.reactive.stateChanged
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] _ in
                guard let `self` = self else { return }
                RemoteGlobalAction.shared().deselectItemsSignal.input.send(value: self.viewModel.pageType)
                self.appEditingView.switchMode(false)
                self.resetCustomAreaToNormal()
            })
        
        disposables += RemoteGlobalAction.shared().statusRemoveButtonSignal
            .output
            .observe(on: QueueScheduler.main)
            .observeValues { [weak self] isEnable in
                self?.appEditingView.isEnableRemoveButton(isEnable)
            }
        
        disposables += RemoteGlobalAction.shared().statusSelectAllButtonSignal
            .output
            .observe(on: QueueScheduler.main)
            .observeValues { [weak self] isEnable in
                self?.appEditingView.switchMode(isEnable)
            }
        
        // States
        powerButton.reactive.image <~ viewModel.imageForPowerButton
            .producer
            .observe(on: QueueScheduler.main)
            .map { $0 }
        
        stackView.reactive.isHidden <~ viewModel.isSwitchOffProperty
            .producer
            .map { $0 }
        
        singlePowerView.powerButton.reactive.image <~ viewModel.imageForPowerButton
            .producer
            .observe(on: QueueScheduler.main)
            .map { $0 }
        
        singlePowerView.reactive.isHidden <~ viewModel.isSwitchOffProperty
            .producer
            .map { !$0 }
        
        padView.touchPadViewContainerView.reactive.isHidden <~ viewModel.isSwitchTouchPadProperty
            .producer
            .observe(on: QueueScheduler.main)
            .map { !$0 }
        
        padView.fourWayPadViewContainerView.reactive.isHidden <~ viewModel.isSwitchTouchPadProperty
            .producer
            .observe(on: QueueScheduler.main)
            .map { $0 }
        
        singlePowerView.reactive.textForFrameTV <~ viewModel.isTextForFrameTV
            .producer
            .observe(on: QueueScheduler.main)
            .map { $0 }
        
        padView.navigateGuideLabel.reactive.isHidden <~ viewModel.isHiddenPadViewGuideLabel
            .producer
            .observe(on: QueueScheduler.main)
        
        disposables += viewModel.isSwitchOffProperty
            .signal
            .observe(on: QueueScheduler.main)
            .observeValues { [weak self] isOff in
                guard let self = self else { return }
                self.singlePowerView.powerButton.stopSpinner()
                self.powerButton.stopSpinner()
                if isOff {
                    self.guideArtModeButtonView.isHidden = true
                    if self.currentContainerHeight > RemotePanelMode.defaultHeight {
                        self.animateContainerHeight(RemotePanelMode.defaultHeight)
                    }
                    self.maximumContainerHeight = RemotePanelMode.defaultHeight
                } else {
                    self.showArtModeGuide()
                    self.maximumContainerHeight = UIDevice.current.is_iPad ? 768 : (UIScreen.main.bounds.height - self.getStatusBarHeight())
                }
            }
        
        disposables += viewModel.isSwitchOfflineProperty
            .map { () }
            .signal
            .observe(on: QueueScheduler.main)
            .observeValues { [weak self] _ in
                self?.animateForSubView(0)
                self?.animateDismissView()
            }
        
        disposables += viewModel.showSourceAndAppEvent
            .output
            .observe(on: QueueScheduler.main)
            .observeValues { [weak self] _ in
                self?.showSourceAndAppView()
                self?.appPageState = .normal
                self?.appEditingView.isHidden = true
            }
        
        disposables += viewModel.scrollCollectionViewProperty
            .producer
            .observe(on: QueueScheduler.main)
            .startWithValues { [weak self] index in
                self?.collectionView.scrollToItem(
                    at: IndexPath(item: index, section: 0),
                    at: .right, animated: false
                )
                self?.pageControlView.currentPage = index
                self?.viewModel.saveRemoteSetting(index: index)
                self?.viewModel.pageType = self?.pageLayouts[index].type ?? .abcd
            }
        
        disposables += viewModel.scrollNumberPadProperty
            .producer
            .filter { $0 != nil }
            .observe(on: QueueScheduler.main)
            .startWithValues({ [weak self] _ in
                guard let `self` = self else { return }
                guard let index = self.pageLayouts.firstIndex(where: { $0.type == .numPad }) else { return }
                self.collectionView.scrollToItem(
                    at: IndexPath(item: index, section: 0),
                    at: .right, animated: false
                )
                self.pageControlView.currentPage = index
                self.viewModel.saveRemoteSetting(index: index)
                self.viewModel.pageType = self.pageLayouts[index].type
                self.animateContainerHeight(self.maximumContainerHeight)
            })
        
        disposables += viewModel.isVoiceSupportProperty
            .producer
            .observe(on: QueueScheduler.main)
            .startWithValues({ [weak self] isSupport in
                guard let `self` = self else { return }
                if let isSupport = isSupport {
                    self.voiceButton.isHidden = !isSupport
                    self.extraButton.isHidden = isSupport
                } else {
                    self.voiceButton.isHidden = false
                    self.extraButton.isHidden = true
                }
            })
        
        disposables += viewModel.voiceStatus
            .signal
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] status in
                guard let `self` = self else { return }
                switch status {
                case .hide:
                    self.remoteVM.stopRecording(self.voiceButton.keyLabel)
                case .recording:
                    if self.voiceLongPressGesture.state == .began || self.voiceLongPressGesture.state == .changed {
                        self.remoteVM.startRecording()
                    }
                case .processing:
                    self.remoteVM.stopRecording(self.voiceButton.keyLabel)
                case .inactive:
                    break
                }
            })
        
        disposables += viewModel.showLuxoButton
            .producer
            .observe(on: QueueScheduler.main)
            .startWithValues { [weak self] isShow in
                guard let self = self else { return }
                
                guard isShow else { return }
                
                let tvYear = TVDeviceManager.shared?.currentTvInfo.tvYear ?? 2017
                if tvYear == 2020 {
                    if self.viewModel.tvCategoryType == .normalTV {
                        self.themesButton.isHidden = false
                    }
                }
                
                self.scaleAndMoveButton.isHidden = false
                self.keyStoneButton.isHidden = false
            }
        
        disposables += viewModel.pageLayoutsProperty
            .producer
            .observe(on: QueueScheduler.main)
            .filter { $0.isNotEmpty }
            .startWithValues({ [weak self] pageLayouts in
                self?.pageLayouts = pageLayouts
                guard let current = self?.pageControlView.currentPage else { return }
                self?.viewModel.pageType = self?.pageLayouts[current].type ?? .abcd
            })
        
        theSeroButton.reactive.isHidden <~ viewModel.showSeroButton
            .producer
            .observe(on: QueueScheduler.main)
            .map { !$0 }
        
        screenRotationButton.reactive.isHidden <~ viewModel.showSeroButton
            .producer
            .observe(on: QueueScheduler.main)
            .map { !$0 }
        
        serviceButton.reactive.isHidden <~ viewModel.showMultiviewButton
            .producer
            .observe(on: QueueScheduler.main)
            .map { !$0 }
        
        multiViewButton.reactive.isHidden <~ viewModel.show2022MultiviewButton
            .producer
            .observe(on: QueueScheduler.main)
            .map { !$0 }
        
        rotationButton.reactive.isHidden <~ viewModel.showRotationButton
            .producer
            .observe(on: QueueScheduler.main)
            .map { !$0 }
    }
    
    private func setupTapButtonAction() {
        disposables += searchButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                RemoteAnalytics.send(RemotePanelMode.remoteScreenID, sender.eventId)
                self?.animateDismissView()
                CLEngine.sharedEngine.presentation?.pushSearchAllVC(animated: true)
            })
        
        disposables += optionMenuButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] _ in
                self?.showOptionDialog()
            })
        
        disposables += settingButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                self?.viewModel.sendClickEvent(sender)
            })
        
        disposables += voiceButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                self?.didTapVoiceButton(sender)
            })
        
        disposables += extraButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                self?.viewModel.sendClickEvent(sender)
            })
        
        disposables += backButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                self?.viewModel.sendClickEvent(sender)
            })
        
        disposables += homeButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                self?.viewModel.sendClickEvent(sender)
            })
        
        disposables += nextButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                self?.viewModel.sendClickEvent(sender)
            })
        
        disposables += padView.topWayButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                self?.viewModel.sendClickEvent(sender)
            })
        
        disposables += padView.rightWayButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                self?.viewModel.sendClickEvent(sender)
            })
        
        disposables += padView.leftWayButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                self?.viewModel.sendClickEvent(sender)
            })
        
        disposables += padView.bottomWayButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                self?.viewModel.sendClickEvent(sender)
            })
        
        disposables += padView.centerButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                self?.viewModel.sendClickEvent(sender)
            })
        
        disposables += rotationButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                self?.viewModel.sendClickEvent(sender)
            })
        
        disposables += multiViewButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                self?.viewModel.sendClickEvent(sender)
            })
        
        disposables += theSeroButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                self?.viewModel.sendClickEvent(sender)
            })
        
        disposables += keyStoneButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                self?.viewModel.sendClickEvent(sender)
            })
        disposables += scaleAndMoveButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                self?.viewModel.sendClickEvent(sender)
            })
        
        disposables += themesButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                self?.viewModel.sendClickEvent(sender)
            })
        
        disposables += screenRotationButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                self?.viewModel.sendClickEvent(sender)
            })
        
        disposables += serviceButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] sender in
                self?.viewModel.sendClickEvent(sender)
            })
        
        disposables += padView.switchTouchPadButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] _ in
                self?.padView.fourWayPadViewContainerView.isHidden = true
                self?.padView.touchPadViewContainerView.isHidden = false
                
                self?.viewModel.saveRemoteSetting(isEnableTouchPad: true)
                RemoteAnalytics.send(RemotePanelMode.remoteScreenID, "TV8143")
            })
        
        disposables += padView.switch4PadButton.reactive.controlEvents(.touchUpInside)
            .observe(on: QueueScheduler.main)
            .observeValues({ [weak self] _ in
                self?.padView.fourWayPadViewContainerView.isHidden = false
                self?.padView.touchPadViewContainerView.isHidden = true
                
                self?.viewModel.saveRemoteSetting(isEnableTouchPad: false)
                RemoteAnalytics.send(RemotePanelMode.remoteScreenID, "TV8142")
            })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        configTouchPad()
        animatePresentContainer()
        showNumberPad()
    }
    
    private func showNumberPad() {
        if let showNumberPad = TVDeviceManager.shared?.numpadState.value.isShow {
            if showNumberPad == true {
                viewModel.scrollNumberPadProperty.value = ()
            } else {
                viewModel.scrollNumberPadProperty.value = nil
            }
        }
    }
    
    func configModeEditing() {
        RemoteAnalytics.send("TV835", "TV0250")
        state = .editing
        for item in pageLayouts {
            item.isEditing = true
        }
        self.collectionView.dragInteractionEnabled = true
        UIView.animate(withDuration: 0.2) {
            self.collectionView.transform = CGAffineTransformMakeScale(0.7, 0.7)
            self.widthCollectionViewContraint.constant = self.state.collectionViewWidth
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.isPagingEnabled = false
            self.collectionView.reloadData()
        }
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
    }
    
    func configModeView() {
        RemoteAnalytics.send("TV835", "TV0252")
        state = .normal
        for item in pageLayouts {
            item.isEditing = false
        }
        self.collectionView.dragInteractionEnabled = false
        UIView.animate(withDuration: 0.2) {
            self.collectionView.transform = CGAffineTransformMakeScale(1.0, 1.0)
            self.widthCollectionViewContraint.constant = self.state.collectionViewWidth
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.isPagingEnabled = true
            self.collectionView.reloadData()
        }
        collectionView.dragDelegate = nil
        collectionView.dropDelegate = nil
    }
    
    func configAppEdit(isEditing: Bool) {
        appPageState = isEditing ? .editing : .normal
        appEditingView.isHidden = isEditing ? false : true
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    private func getRotationAccessoryStatus() {
        TVOCFAodBrowserClient().getRotationAccessoryStatus { status in
            TVDeviceManager.rotationAccessoryStatus.value = status
        }
    }
    
    private func configVibration() {
        if AppDefault.shared.isVibrationEffect == nil {
            AppDefault.shared.isVibrationEffect = true
        }
    }
}

// MARK: - Layouts
extension TVRemoteControlNewY23ViewController {
    func layouts() {
        view.addSubview(dimmedView)
        view.addSubview(containerView)
        view.addSubview(guideArtModeButtonView)
        
        setupScrollView()
        contentView.addSubview(stackView)
        contentView.addSubview(singlePowerView)
        contentView.addSubview(dragIconView)
        contentView.addSubview(appEditingView)
        dragIconView.addSubview(dragIcon)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        optionMenuStackView.translatesAutoresizingMaskIntoConstraints = false
        
        displayFunctionsView(hide: true)
        collectionContainerView.constraintsTo(view: bottomView, positions: .top)
        collectionContainerView.constraintsTo(view: bottomView, positions: .left)
        collectionContainerView.constraintsTo(view: bottomView, positions: .right)
        collectionView.constraintsTo(view: collectionContainerView, positions: .centerView)
        
        widthCollectionViewContraint = collectionView.widthAnchor.constraint(equalToConstant: state.collectionViewWidth)
        widthCollectionViewContraint.isActive = true
        
        collectionView.heightItem(168)
        let bottomHeight: Double = 200 + Double(bottomAreaHeight ?? 0)
        bottomView.heightItem(bottomHeight)
        collectionContainerView.heightItem(186)
        
        pageControlContainerView.constraintsTo(view: bottomView, positions: .bottom)
        pageControlContainerView.constraintsTo(view: bottomView, positions: .left)
        pageControlContainerView.constraintsTo(view: bottomView, positions: .right)
        pageControlContainerView.constraintsTo(view: collectionContainerView, positions: .below, constant: -12)
        pageControlView.heightItem(28)
        pageControlView.constraintsTo(view: pageControlContainerView, positions: .left)
        pageControlView.constraintsTo(view: pageControlContainerView, positions: .right)
        pageControlView.constraintsTo(view: pageControlContainerView, positions: .top)
        pageControlView.numberOfPages = pageLayouts.count
        
        dimmedView.constraintsTo(view: view)
        
        if TVDeviceManager.shared?.tvPowerState == false {
            maximumContainerHeight = RemotePanelMode.defaultHeight
        } else {
            maximumContainerHeight = UIDevice.current.is_iPad ? 768 : (UIScreen.main.bounds.height - getStatusBarHeight())
        }
        
        containerView.constraintsTo(view: view, positions: .bottom)
        
        if UIDevice.current.is_iPad {
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            contentView.widthItem(375)
            contentView.constraintsTo(view: view, positions: .right)
        } else {
            contentView.constraintsTo(view: view, positions: .bottom)
            contentView.constraintsTo(view: view, positions: .left)
            contentView.constraintsTo(view: view, positions: .right)
        }
        
        containerViewHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 0)
        containerViewHeightConstraint?.isActive = true
        
        touchPadContainerHeightConstraint = padView.heightAnchor.constraint(lessThanOrEqualToConstant: 325)
        touchPadContainerHeightConstraint?.isActive = true
        
        padView.heightAnchor.constraint(greaterThanOrEqualToConstant: 204).isActive = true
        settingView.heightAnchor.constraint(lessThanOrEqualToConstant: 64).isActive = true
        settingViewContainer.translatesAutoresizingMaskIntoConstraints = false
        settingViewContainer.constraintsTo(view: settingView)
        
        dragIcon.constraintsTo(view: topView, positions: .centerX)
        topDragIconContraint = NSLayoutConstraint(item: dragIcon, attribute: .top, relatedBy: .equal, toItem: powerButton, attribute: .top, multiplier: 1, constant: 0)
        topDragIconContraint.isActive = true
        dragIcon.widthItem(40)
        dragIconView.constraintsTo(view: dragIcon, positions: .centerView)
        dragIconView.sizeItem(50)
        
        stackView.constraintsTo(view: contentView, positions: .top)
        stackView.constraintsTo(view: contentView, positions: .left)
        stackView.constraintsTo(view: contentView, positions: .right)
        stackView.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor).isActive = true
        
        topView.heightItem(60)
        
        powerButton.sizeItem(36)
        powerButton.constraintsTo(view: topView, positions: .top, constant: 16)
        powerButton.constraintsTo(view: settingButton, positions: .centerX)
        
        optionMenuStackView.constraintsTo(view: topView, positions: .top, constant: 16)
        optionMenuStackView.constraintsTo(view: topView, positions: .right, constant: -16)
        
        optionMenuButton.sizeItem(36)
        searchButton.sizeItem(36)
        
        settingButton.sizeItem(60)
        settingButton.constraintsTo(view: settingViewContainer, positions: .centerY)
        settingButton.constraintsTo(view: settingViewContainer, positions: .left, constant: 32)
        
        voiceButton.sizeItem(60)
        voiceButton.constraintsTo(view: settingViewContainer, positions: .centerY)
        voiceButton.constraintsTo(view: settingViewContainer, positions: .right, constant: -32)
        
        extraButton.sizeItem(60)
        extraButton.constraintsTo(view: settingViewContainer, positions: .centerY)
        extraButton.constraintsTo(view: settingViewContainer, positions: .right, constant: -32)
        
        backButton.sizeItem(60)
        backButton.constraintsTo(view: funtionalView, positions: .centerY)
        backButton.constraintsTo(view: funtionalView, positions: .left, constant: 32)
        
        homeButton.sizeItem(60)
        homeButton.constraintsTo(view: funtionalView, positions: .centerView)
        
        nextButton.sizeItem(60)
        nextButton.constraintsTo(view: funtionalView, positions: .centerY)
        nextButton.constraintsTo(view: funtionalView, positions: .right, constant: -32)
        
        singlePowerView.constraintsTo(view: contentView)
        
        funtionalView.heightItem(76)
        
        separator1View.heightItem(24)
        separator2View.heightItem(24)
        
        let stkLeading = stackViewFunctions.leadingAnchor.constraint(greaterThanOrEqualTo: settingButton.trailingAnchor, constant: 0)
        stkLeading.priority = UILayoutPriority(750)
        stkLeading.isActive = true
        
        let stkTrailling = stackViewFunctions.trailingAnchor.constraint(greaterThanOrEqualTo: voiceButton.leadingAnchor, constant: 0)
        stkTrailling.priority = UILayoutPriority(750)
        stkTrailling.isActive = true
        
        stackViewFunctions.constraintsTo(view: settingViewContainer, positions: .centerX)
        stackViewFunctions.constraintsTo(view: settingButton, positions: .top)
        
        let screenRemoteSize = UIDevice.current.is_iPad ? 375 : UIScreen.main.bounds.width
        let spacing = (screenRemoteSize - (60 * 4) - (36*2)) / 3
        stackViewFunctions.spacing = spacing
        
        appEditingView.constraintsTo(view: contentView, positions: .top)
        appEditingView.constraintsTo(view: contentView, positions: .left)
        appEditingView.constraintsTo(view: contentView, positions: .right)
        appEditingView.constraintsTo(view: bottomView, positions: .above)
        
        setupArtModeGuideView()
    }
    
    func displayFunctionsView(hide: Bool = true) {
        settingViewContainer.isHidden = hide
    }
    
    func setupScrollView() {
        containerView.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        scrollView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
    }
    
    private func setupArtModeGuideView() {
        guideArtModeButtonView.constraintsTo(view: self.view)
        guideArtModeButtonView.addSubview(guideImageView)
        
        guideBackgroundWhiteView.widthItem(280)
        guideBackgroundWhiteView.heightItem(120)
        guideBackgroundWhiteView.constraintsTo(view: scrollView, positions: .left, constant: 20)
        guideBackgroundWhiteView.constraintsTo(view: scrollView, positions: .above, constant: -20)
        
        guideLabel.constraintsTo(view: guideBackgroundWhiteView, positions: .top, constant: 16)
        guideLabel.constraintsTo(view: guideBackgroundWhiteView, positions: .left, constant: 16)
        guideLabel.constraintsTo(view: guideBackgroundWhiteView, positions: .bottom, constant: -16)
        guideLabel.constraintsTo(view: guideBackgroundWhiteView, positions: .right, constant: -16)
        guidePowerButton.sizeItem(36)
        guidePowerButton.backgroundColor = .white
        
        guideImageView.widthItem(16)
        guideImageView.constraintsTo(view: guideBackgroundWhiteView, positions: .below)
        guideImageView.constraintsTo(view: powerButton, positions: .centerX)
        guideImageView.constraintsTo(view: scrollView, positions: .above)
        
        let firstStringAttributed = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
            NSAttributedString.Key.foregroundColor: UIColor(hexString: "#FF3695DD")
        ]
        
        let secondStringAttributed = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
            NSAttributedString.Key.foregroundColor: UIColor.black
        ]
        
        let firstString = NSMutableAttributedString(
            string: CoreSIDManager.artmodePowerGuideButton.getString(),
            attributes: firstStringAttributed
        )
        
        let secondString = NSAttributedString(
            string: TVLocalizedString("MAPP_SID_IOTTHIGNS_TAP_SWITHC_TV_MODE_ART_MODE"),
            attributes: secondStringAttributed
        )
        firstString.append(NSAttributedString(string: " "))
        firstString.append(secondString)
        
        guideLabel.attributedText = firstString
        
        guidePowerButton.constraintsTo(view: powerButton)
    }
    
    private func showArtModeGuide() {
        CLLogDebug(.CORE, "showArtModeGuide")
        switch self.tvStatus {
        case .tvOff, .disconnect:
            DispatchQueue.main.async {
                self.guideArtModeButtonView.isHidden = true
            }
        case .tvOn:
            let tvCategoryType = TVDeviceManager.shared?.currentTvInfo.deviceInfo.tvCategoryType ?? .normalTV
            if tvCategoryType == .frameTV {
                if !AppDefault.shared.isWatchedArtmodeButtonGuide && self.currentContainerHeight == RemotePanelMode.defaultHeight {
                    DispatchQueue.main.async {
                        self.guideArtModeButtonView.isHidden = false
                    }
                }
            }
        default:
            if TVDeviceManager.shared?.tvPowerState == true {
                let tvCategoryType = TVDeviceManager.shared?.currentTvInfo.deviceInfo.tvCategoryType ?? .normalTV
                if tvCategoryType == .frameTV {
                    if !AppDefault.shared.isWatchedArtmodeButtonGuide && self.currentContainerHeight == RemotePanelMode.defaultHeight {
                        DispatchQueue.main.async {
                            self.guideArtModeButtonView.isHidden = false
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.guideArtModeButtonView.isHidden = true
                }
            }
        }
    }
    
    func resetCustomAreaToNormal() {
        appPageState = .normal
        appEditingView.isHidden = true
        collectionView.reloadData()
    }
}

extension TVRemoteControlNewY23ViewController: TVRemoteControlNewY23Delegate {
    func didTVStatusChanged(_ status: TVStatusType) {
        self.tvStatus = status
    }
    
    func d2dSupportStatus(_ status: Bool) {
        self.isD2dSupport = status
    }
    
    func touchPadDetectDirection(_ direction: Bool) {
        self.updateTouchpad(direction)
    }
}

// MARK: - Config ContainerView
extension TVRemoteControlNewY23ViewController {
    func animatePresentContainer() {
        UIView.animate(withDuration: 0.4) {
            self.containerViewHeightConstraint?.constant = self.currentContainerHeight
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.showArtModeGuide()
        }
    }

    func animateDismissView() {
        // hide blur view
        UIView.animate(withDuration: 0.4) {
            self.containerViewHeightConstraint?.constant = 0
            self.touchPadContainerHeightConstraint?.constant = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            RemoteGlobalAction.dispose()
            self.dismiss(animated: false)
        }
    }
    
    func setupPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(gesture:)))
        panGesture.delaysTouchesBegan = false
        panGesture.delaysTouchesEnded = false
        dragIconView.addGestureRecognizer(panGesture)
        let panGesture1 = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(gesture:)))
        panGesture1.delaysTouchesBegan = false
        panGesture1.delaysTouchesEnded = false
        topView.addGestureRecognizer(panGesture1)
        let panGesture2 = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(gesture:)))
        panGesture2.delaysTouchesBegan = false
        panGesture2.delaysTouchesEnded = false
        settingView.addGestureRecognizer(panGesture2)
        let panGesture3 = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(gesture:)))
        panGesture3.delaysTouchesBegan = false
        panGesture3.delaysTouchesEnded = false
        separator1View.addGestureRecognizer(panGesture3)
        
        let tapArtModeButtonIcon = UITapGestureRecognizer(target: self, action: #selector(handleTapArtModeGuide))
        guideArtModeButtonView.addGestureRecognizer(tapArtModeButtonIcon)
        
        let tapArtModeWhiteView = UITapGestureRecognizer(target: self, action: #selector(handleTapArtModeWhiteGuideView))
        guideBackgroundWhiteView.addGestureRecognizer(tapArtModeWhiteView)
        
        let tapDragIcon = UITapGestureRecognizer(target: self, action: #selector(handleTapDragIcon))
        dragIconView.isUserInteractionEnabled = true
        dragIconView.addGestureRecognizer(tapDragIcon)
    }

    @objc func handleTapArtModeGuide() {
        guideArtModeButtonView.isHidden = true
        AppDefault.shared.isWatchedArtmodeButtonGuide = true
    }
    
    @objc func handleTapArtModeWhiteGuideView() {
        CLLogDebug("handleTapArtModeWhiteGuideView")
    }

    @objc func handleTapDragIcon() {
        if TVDeviceManager.shared?.tvPowerState == false { return }
        if currentContainerHeight > RemotePanelMode.defaultHeight {
            //animateContainerHeight(RemotePanelMode.defaultHeight)
            animateForSubView(0)
            animateDismissView()
        } else {
            animateContainerHeight(maximumContainerHeight)
        }
    }
    
    @objc func handlePanGesture(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let isDraggingDown = translation.y > 0
        let newHeight = currentContainerHeight - translation.y
        
        switch gesture.state {
        case .changed:
            if newHeight < maximumContainerHeight {
                containerViewHeightConstraint?.constant = newHeight
                view.layoutIfNeeded()
            }
            if settingView.frame.size.height > RemotePanelMode.appSize {
                self.displayFunctionsView(hide: false)
            } else if settingView.frame.size.height < 50 {
                self.displayFunctionsView(hide: true)
            }
        case .ended:
            // If new height is below min, dismiss controller
            if newHeight < RemotePanelMode.dismissibleHeight {
                if singlePowerView.isHidden {
                    RemoteAnalytics.send("TV031", "TV0282")
                } else {
                    RemoteAnalytics.send("TV032", "TV0230")
                }
                animateForSubView(0)
                animateDismissView()
            } else if newHeight < RemotePanelMode.defaultHeight {
                // If new height is below default, animate back to default
                animateContainerHeight(RemotePanelMode.defaultHeight)
            } else if newHeight < maximumContainerHeight && isDraggingDown {
                // If new height is below max and going down, set to dismiss view
                RemoteAnalytics.send("TV031", "TV0283")
                animateForSubView(0)
                animateDismissView()
            } else if newHeight > RemotePanelMode.defaultHeight && !isDraggingDown {
                // If new height is below max and going up, set to max height at top
                RemoteAnalytics.send("TV031", "TV0281")
                animateContainerHeight(maximumContainerHeight)
            }
        default:
            break
        }
    }
    
    func animateContainerHeight(_ height: CGFloat) {
        self.animateForSubView(height)
        UIView.animate(withDuration: 0.4, animations: {
            self.containerViewHeightConstraint?.constant = height
            self.view.layoutIfNeeded()
        }, completion: { [weak self] _ in
            guard let `self` = self else { return }
            
            self.currentContainerHeight = height
            
            if !AppDefault.shared.isWatchedGuideline && height == self.maximumContainerHeight {
                self.showRemoteHowToUse()
            }
            
            if !AppDefault.shared.isWatchedArtmodeButtonGuide && height == RemotePanelMode.defaultHeight {
                self.showArtModeGuide()
            }
        })
    }
    
    func animateForSubView(_ height: CGFloat) {
        let isHidden = height <= RemotePanelMode.defaultHeight
        CLLogDebug("isHidden: \(isHidden ? "true" : "false")")
        self.displayFunctionsView(hide: isHidden)
        self.optionMenuButton.isHidden = isHidden
        self.separator1View.isHidden = isHidden
        self.separator2View.isHidden = isHidden
        self.topDragIconContraint.constant = isHidden ? 8 : 12
    }
    
    private func showOptionDialog() {
        optionsDialog.spill(on: contentView)
        contentView.bringSubviewToFront(optionsDialog)
    }
    
    private func showRemoteOptions() {
        let viewController = RemoteOptionsViewController(themeVM: self.themeVM)
        if UIDevice.current.is_iPad {
            viewController.modalPresentationStyle = .overFullScreen
            viewController.modalTransitionStyle = .crossDissolve
            self.navigationController?.present(viewController, animated: true)
        } else {
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    private func showRemoteHowToUse() {
        let viewController = GuidelineViewController()
        viewController.modalPresentationStyle = .overFullScreen
        viewController.modalTransitionStyle = .crossDissolve
        
        self.navigationController?.present(viewController, animated: true)
    }
    
    private func showSourceAndAppView() {
        if let sourceAndAppView = sourceAndAppView, sourceAndAppView.isDescendant(of: contentView) {
            return
        }
        
        sourceAndAppView = AppAndSourceView()
        
        if let sourceAndAppView = sourceAndAppView {
            sourceAndAppView.translatesAutoresizingMaskIntoConstraints = false
            
            contentView.addSubview(sourceAndAppView)
            contentView.bringSubviewToFront(sourceAndAppView)
            
            sourceAndAppView.constraintsTo(view: contentView, positions: .top)
            sourceAndAppView.constraintsTo(view: contentView, positions: .left)
            sourceAndAppView.constraintsTo(view: contentView, positions: .right)
            sourceAndAppView.constraintsTo(view: bottomView, positions: .above)
        }
    }
}

// MARK: - Config touchPad
extension TVRemoteControlNewY23ViewController {
    private func configNavigateGuide() {
        padView.navigateGuideLabel.isHidden = defaults.integer(forKey: viewModel.key) >= swipeCounter ? true : false
    }
    
    private func configTouchPad() {
        pointerStatus = remoteVM.getPointerEnabledStatus()
        
        padView.touchPad.detectDirection = !pointerStatus
        padView.touchPad.delegate = viewModel
    }
    
    private func updateTouchpad(_ direction: Bool) {
        pointerStatus = direction
        padView.touchPad.detectDirection = !direction
    }
}

// MARK: - Remote Event
extension TVRemoteControlNewY23ViewController {
    func didTapVoiceButton(_ sender: RemoteKeyButton) {
        viewModel.remoteGestureHelper.addHapticEffect()
        guard self.isD2dSupport else {
            self.showVoiceSupportPopup()
            return
        }
        
        if let allowed = isMircohoneAceesAllowed() {
            if allowed {
                remoteVM.sendClickEvent(voiceButton.keyLabel, connectionType: .d2d)
                RemoteAnalytics.send(RemotePanelMode.remoteScreenID, voiceButton.eventId, "Press", 1)
            } else {
                showVoicePermissionPopup()
            }
        }
    }
    
    @objc
    func didLongPressVoiceButton(_ sender: UILongPressGestureRecognizer) {
        guard self.isD2dSupport else {
            self.showVoiceSupportPopup()
            return
        }
        
        switch sender.state {
        case .began:
            if let allowed = isMircohoneAceesAllowed() {
                if allowed {
                    remoteVM.sendTouchDown(voiceButton.keyLabel, connectionType: .d2d)
                    RemoteAnalytics.send(RemotePanelMode.remoteScreenID, voiceButton.eventId, "Long Press", 2)
                } else {
                    showVoicePermissionPopup()
                }
            }
        case .ended:
            if let allowed = isMircohoneAceesAllowed() {
                if allowed {
                    remoteVM.stopRecording(voiceButton.keyLabel)
                }
            }
        default:
            break
        }
    }
    
    private func showPopupTurnOffFrameTV() {
        CoreAnalytics.Popup.powerOffTheFrameAlert.send()
        
        let title = TVLocalizedString("MAPP_SID_IOT_CONTROL_REMOTE_POWER_FOR_ACCESSIBILITY")
        let message = FrameSIDManager.turnOffDevice.getString()
        
        let okButtonTitle = TVLocalizedString("COM_SID_OK")
        let cancelButtonTitle = TVLocalizedString("COM_BUTTON_CANCEL")
        
        Globals.alert?.showDialog(titleText: title, messageText: message, firstButtonText: cancelButtonTitle, secondButtonText: okButtonTitle) { [weak self] tappedString in
            guard let `self` = self else { return }
            
            if tappedString == okButtonTitle {
                CoreAnalytics.Popup.powerOffTheFrameOk.send()
                RemoteAnalytics.send(RemotePanelMode.remoteScreenID, self.powerButton.eventId)
                self.powerButton.startSpinner()
                self.ocfRemoteClient.setSwitch(value: false)
            }
            
            if tappedString == cancelButtonTitle {
                CoreAnalytics.Popup.powerOffTheFrameCancel.send()
            }
        }
    }
}

// MARK: - Config CollectionView
extension TVRemoteControlNewY23ViewController {
    private func configCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isUserInteractionEnabled = true
    }
    
    @objc func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        self.longPressEditing()
    }
    
    func longPressEditing() {
        guard state == .normal else { return }
        
        configModeEditing()
    }
}

extension TVRemoteControlNewY23ViewController {
    func showQuickOption(with item: AppCellModelData, view: UIView, containerView: UIView) {
        if appPageState == .editing { return }
        if quickOption.isNotNil { return }
        
        sourceAndAppView?.closeSourceAndAppView()
        
        quickOption = QuickOption(dismissed: { [weak self] in
            guard let self = self else { return }
            self.quickOption = nil
        })
        
        let selectAction = QuickOptionAction(
            title: TVLocalizedString("DREAM_SAC_TBOPT_SELECT", comment: "Select"),
            image: UIImage(named: "icon_bb_select", in: Bundle.TV, compatibleWith: nil)
        ) { [weak self] in
            RemoteAnalytics.send("TV029", "TV0270")
            self?.configAppEdit(isEditing: true)
        }

        let deleteAction = QuickOptionAction(
            title: TVLocalizedString("COM_IDWS_MOIP_SKYPE_REMOVE_KR_MNT", comment: "Remove"),
            image: UIImage(named: "icon_bb_delete", in: Bundle.TV, compatibleWith: nil)
        ) { [weak self] in
            guard let `self` = self else { return }
            RemoteAnalytics.send("TV029", "TV0271")
            if let data = item.data {
                self.viewModel.removePageApp(item: data)
                RemoteGlobalAction.shared().deleteItemSignal.input.send(value: ())
            }
        }
        
        var actions: [QuickOptionAction] {
            var actions: [QuickOptionAction] = []
            actions.append(selectAction)
            actions.append(deleteAction)
            return actions
        }
   
        quickOption?.addActions(actions)
        
        quickOption?.presentPointingAtView(view, containerView: containerView)
    }
    
    private func hideQuickOption() {
        quickOption?.dismissAnimated(true)
        quickOption = nil
    }

    private func showToast(text: String, duration: Double = 1) {
        CLLogDebug("showToast")
    }
}

extension TVRemoteControlNewY23ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pageLayouts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let presetView = pageLayouts[indexPath.item]
        switch presetView.type {
        case .tvControl:
            let cell = collectionView.dequeueReusableCell(with: PageControlCell.self, for: indexPath) as PageControlCell
            cell.setData(viewModel: pageLayouts[indexPath.item], remoteVM: self.remoteVM, themeVM: themeVM)
            cell.delegate = self
            return cell
            
        case .numPad:
            let cell = collectionView.dequeueReusableCell(with: PageNumberCell.self, for: indexPath) as PageNumberCell
            cell.numberView.setupStyleObserver(themeVM: self.themeVM)
            cell.setData(viewModel: pageLayouts[indexPath.item], remoteGestureHelper: remoteGestureHelper, remoteVM: self.remoteVM, controlVM: viewModel)
            cell.delegate = self
            return cell
            
        case .applicationConfig:
            let cell = collectionView.dequeueReusableCell(with: PageAppCell.self, for: indexPath) as PageAppCell
            cell.setData(viewModel: pageLayouts[indexPath.item], appEditing: appPageState == .editing)
            cell.delegate = self
            return cell
            
        case .tvControlAndApplicationConfig:
            let cell = collectionView.dequeueReusableCell(with: PageSoundAndAppCell.self, for: indexPath) as PageSoundAndAppCell
            cell.setData(viewModel: pageLayouts[indexPath.item], remoteVM: self.remoteVM, themeVM: themeVM, appEditing: appPageState == .editing)
            cell.delegate = self
            return cell
            
        case .abcd:
            let cell = collectionView.dequeueReusableCell(with: PageABCDCell.self, for: indexPath) as PageABCDCell
            cell.setData(viewModel: pageLayouts[indexPath.item], remoteGestureHelper: remoteGestureHelper, remoteVM: self.remoteVM, controlVM: viewModel, themeVM: themeVM)
            cell.delegate = self
            return cell
            
        default:
            let cell = collectionView.dequeueReusableCell(with: PageCell.self, for: indexPath) as PageCell
            cell.setData(viewModel: pageLayouts[indexPath.item])
            return cell
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: contentView.frame.width, height: 160)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if state == .editing {
            self.configModeView()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                self.scrollToTargetPage(indexPath: indexPath)
            })
        }
    }
    
    func scrollToTargetPage(indexPath: IndexPath) {
        self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        self.pageControlView.currentPage = indexPath.item
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return state.padding
    }
    
    // Custom Reorder action
    private func reorderItems(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView) {
        let items = coordinator.items
        if items.count == 1, let item = items.first, let sourceIndexPath = item.sourceIndexPath {
            var dIndexPath = destinationIndexPath
            if dIndexPath.row >= collectionView.numberOfItems(inSection: 0) {
                dIndexPath.row = collectionView.numberOfItems(inSection: 0) - 1
            }
            collectionView.performBatchUpdates({
                pageLayouts.remove(at: sourceIndexPath.row)
                guard let localObj = item.dragItem.localObject as? PageCellViewModel else { return }
                pageLayouts.insert(localObj, at: dIndexPath.row)
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [dIndexPath])
                self.viewModel.saveRemoteSetting(pageLayouts: pageLayouts)
                self.viewModel.saveRemoteSetting(index: dIndexPath.row)
            })
            guard let item = items.first?.dragItem else { return }
            coordinator.drop(item, toItemAt: dIndexPath)
            collectionView.scrollToItem(at: dIndexPath, at: [.centeredVertically, .centeredHorizontally], animated: true)
            pageControlView.currentPage = dIndexPath.item
        }
    }
}

// MARK: - CollectionView Drag & Drop
extension TVRemoteControlNewY23ViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            // Get last index path of table view.
            let section = collectionView.numberOfSections - 1
            let row = collectionView.numberOfItems(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        
        switch coordinator.proposal.operation {
        case .move:
            self.reorderItems(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)
        case .copy:
            break
        default:
            return
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return nil }
        RemoteAnalytics.send("TV835", "TV0251")
        let previewParameters = UIDragPreviewParameters()
        let path = UIBezierPath(roundedRect: cell.contentView.frame, cornerRadius: 24.0)
        previewParameters.visiblePath = path
        previewParameters.backgroundColor = .clear
        return previewParameters
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        let item = self.pageLayouts[indexPath.item]
        let itemProvider = NSItemProvider(object: item as PageCellViewModel)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = self.pageLayouts[indexPath.item]
        let itemProvider = NSItemProvider(object: item as PageCellViewModel)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if collectionView.hasActiveDrag {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
    }
}

extension TVRemoteControlNewY23ViewController: PageControlCellDelegate {
    func longPressPageControlCell(cell: PageControlCell, gesture: UILongPressGestureRecognizer) {
        self.longPressEditing()
    }
}

extension TVRemoteControlNewY23ViewController: PageNumberCellDelegate {
    func longPressPageNumberCell(cell: PageNumberCell, gesture: UILongPressGestureRecognizer) {
        self.longPressEditing()
    }
}

extension TVRemoteControlNewY23ViewController: PageAppCellDelegate {
    func longPressPageAppConfigCell(cell: PageAppCell, gesture: UILongPressGestureRecognizer) {
        self.longPressEditing()
    }
}

extension TVRemoteControlNewY23ViewController: PageABCDCellDelegate {
    func longPressPageABCDCell(cell: PageABCDCell, gesture: UILongPressGestureRecognizer) {
        self.longPressEditing()
    }
}

extension TVRemoteControlNewY23ViewController: PageSoundAndAppCellDelegate {
    func longPressAppCell(cell: AppCell, item: AppCellModelData, gesture: UILongPressGestureRecognizer) {
        self.showQuickOption(with: item, view: cell, containerView: self.view)
    }
    
    func longPressControlAndAppConfigCell(cell: PageSoundAndAppCell, gesture: UILongPressGestureRecognizer) {
        self.longPressEditing()
    }
}

extension TVRemoteControlNewY23ViewController {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let currentIndex = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        if !self.appEditingView.isHidden {
            RemoteGlobalAction.shared().deselectItemsSignal.input.send(value: pageLayouts[currentIndex].type)
            self.appEditingView.switchMode(false)
            self.appPageState = .normal
            self.appEditingView.isHidden = true
            self.collectionView.reloadData()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let widthCell = scrollView.frame.width
        if state == .editing {
            let currentIndex = Int(scrollView.contentOffset.x) / Int(widthCell * 0.7)
            
            if currentIndex >= pageLayouts.count {
                pageControlView.currentPage = currentIndex - 1
                viewModel.saveRemoteSetting(index: currentIndex - 1)
                viewModel.pageType = pageLayouts[currentIndex-1].type
            } else {
                pageControlView.currentPage = currentIndex
                viewModel.saveRemoteSetting(index: currentIndex)
                viewModel.pageType = pageLayouts[currentIndex].type
            }
        } else {
            let currentIndex = Int(scrollView.contentOffset.x) / Int(widthCell)
            pageControlView.currentPage = currentIndex
            viewModel.saveRemoteSetting(index: currentIndex)
            viewModel.pageType = pageLayouts[currentIndex].type
            if pageLayouts[currentIndex].type == .applicationConfig ||
                pageLayouts[currentIndex].type == .tvControlAndApplicationConfig {
                viewModel.syncSourceAndApps()
            }
            
            switch pageLayouts[currentIndex].type {
            case .abcd:
                RemoteAnalytics.send(RemotePanelMode.pageABCDScreenID, "TV0240")
                
            case .numPad:
                RemoteAnalytics.send(RemotePanelMode.pageNumberScreenID, "TV0241")
                
            case .tvControl:
                RemoteAnalytics.send(RemotePanelMode.pageControlScreenID, "TV0242")
                
            case .tvControlAndApplicationConfig:
                RemoteAnalytics.send(RemotePanelMode.pageSoundAndAppScreenID, "TV0243")
                
            case .applicationConfig:
                RemoteAnalytics.send(RemotePanelMode.pageAppScreenID, "TV0244")
                
            default:
                break
            }
        }
        
    }
}


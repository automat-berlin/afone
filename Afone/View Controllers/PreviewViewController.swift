//
// Automat
//
// Copyright (c) 2019 Automat Berlin GmbH - https://automat.berlin/
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

class PreviewViewController: BaseViewController {

    // MARK: Public vars

	var isDebugEnabled: Bool {
		didSet {
			dynamicAnimator.setValue(isDebugEnabled, forKey: "debugEnabled")
		}
	}

	var dynamicsView: UIView? {
		didSet {
			dynamicsView != nil ? setupDynamics() : resetDynamics()
		}
	}

    // MARK: Private vars

	private lazy var dynamicAnimator: UIDynamicAnimator = {
		let animator = UIDynamicAnimator(referenceView: view)
		animator.delegate = self
		return animator
	}()

	private lazy var collision: UICollisionBehavior? = {
		guard let dynamicsView = dynamicsView else {
			return nil
		}
		let collision = UICollisionBehavior(items: [dynamicsView])
		collision.translatesReferenceBoundsIntoBoundary = true
		return collision
	}()

	private lazy var itemBehavior: UIDynamicItemBehavior? = {
		guard let dynamicsView = dynamicsView else {
			return nil
		}

		let itemBehavior = UIDynamicItemBehavior(items: [dynamicsView])
		itemBehavior.density = 0.03
		itemBehavior.resistance = 8
		itemBehavior.friction = 0.0
		itemBehavior.allowsRotation = false
		return itemBehavior
	}()

	private lazy var panGesture: UIPanGestureRecognizer = {
		return UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(sender:)))
	}()

	private lazy var attachment: UIAttachmentBehavior? = {
		guard let dynamicsView = dynamicsView else {
			return nil
		}

		return UIAttachmentBehavior(item: dynamicsView, attachedToAnchor: .zero)
	}()

    // MARK: Initializers

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		isDebugEnabled = false
		dynamicsView = UIView(frame: .zero)

		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}

	required init?(coder aDecoder: NSCoder) {
		isDebugEnabled = false
		dynamicsView = UIView(frame: .zero)

		super.init(coder: aDecoder)
	}
}

// MARK: UIDynamicAnimatorDelegate

extension PreviewViewController: UIDynamicAnimatorDelegate {

    // MARK: Public func to override in subclass

    func movableViewFrameCanBeChanged() {
    }

	func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
		movableViewFrameCanBeChanged()
	}
}

// MARK: UIDynamics creator and destructor

extension PreviewViewController {

    private func setupDynamics() {
        guard let dynamicsView = dynamicsView,
            dynamicAnimator.behaviors.isEmpty,
            let collision = collision,
            let itemBehavior = itemBehavior else {
                return
        }

        dynamicAnimator.addBehavior(collision)
        dynamicAnimator.addBehavior(itemBehavior)

        // Offset between gravity fields
        let offset: CGFloat = 50.0

        /*
         Positions are:

         |-------|
         | * | * |
         | * | * |
         |------ |

         */
        let positions = [CGPoint(x: (view.bounds.midX / 2), y: (view.bounds.midY / 2 - offset)),
                         CGPoint(x: (view.bounds.maxX / 4 * 3), y: (view.bounds.midY / 2 - offset)),
                         CGPoint(x: (view.bounds.midX / 2), y: (view.bounds.maxY / 4 * 3 + offset)),
                         CGPoint(x: (view.bounds.maxX / 4 * 3), y: (view.bounds.maxY / 4 * 3 + offset))]

        for position in positions {
            let springField = UIFieldBehavior.springField()
            springField.position = position
            springField.strength = 2.0
            let size = CGSize(width: (view.bounds.size.width / 2), height: (view.bounds.size.height / 2) + (offset * 2))
            springField.region = UIRegion(size: size)

            dynamicAnimator.addBehavior(springField)
            springField.addItem(dynamicsView)
        }

        dynamicsView.addGestureRecognizer(panGesture)
    }

    private func resetDynamics() {
        guard let movableView = dynamicsView,
            !dynamicAnimator.behaviors.isEmpty else {
                return
        }

        dynamicAnimator.removeAllBehaviors()
        movableView.removeGestureRecognizer(panGesture)
    }
}

// MARK: UIPanGestureRecognizer Selector

extension PreviewViewController {

    @objc private func handlePanGesture(sender: UIPanGestureRecognizer) {
        guard
            let attachment = attachment,
            let movableView = dynamicsView else {
                return
        }

        let location = sender.location(in: view)
        let velocity = sender.velocity(in: view)
        switch sender.state {
        case .began:
            attachment.anchorPoint = location
            dynamicAnimator.addBehavior(attachment)
        case .changed:
            attachment.anchorPoint = location
        case .cancelled,
             .ended,
             .failed,
             .possible:
            itemBehavior?.addLinearVelocity(velocity, for: movableView)
            dynamicAnimator.removeBehavior(attachment)
        @unknown default:
            fatalError("Switch encountered unknown state: See PreviewViewController.swift")
        }
    }
}

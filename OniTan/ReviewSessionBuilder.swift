import Foundation

enum ReviewSessionBuilder {

    static func buildReviewStage(reviewQuestions: [Question]) -> Stage {
        Stage(stage: -1, questions: reviewQuestions)
    }
}

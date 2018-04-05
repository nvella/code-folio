import * as Joi from 'joi';

export class ObjNotFoundError extends Error {
    constructor(message?: string) {
        super(message || 'obj not found in db');
        this.name = 'ObjNotFoundError';
    }
}

export class ValidationError extends Error {
    joiError: Joi.ValidationError;

    constructor(message?: string, joiError?: Joi.ValidationError) {
        super(message || 'validation error');
        this.name = 'ValidationError';
        this.joiError = joiError;
    }
}
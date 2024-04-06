<?php

declare(strict_types=1);

namespace App\Exception;

/** @method static self create(array $params = []) */
final class EmailIsNotValidException extends \Exception
{
    public const TRANSLATOR_PHRASE = 'verification_exception.email_is_not_valid_error';
}